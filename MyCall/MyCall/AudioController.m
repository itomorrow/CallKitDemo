//
//  AudioController.m
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import "AudioController.h"
#import <AVFoundation/AVFAudio.h>

@interface AudioController ()

@property (nonatomic, assign) _Nonnull id <AudioControllerDelegate> delegate;

@property (nonatomic, assign) AudioUnit   audioUnit;

@property (nonatomic, assign) AudioStreamBasicDescription outputAudioDescription;
@property (nonatomic, assign) AudioStreamBasicDescription inputAudioDescription;

@property (nonatomic, assign) BOOL   initiallized;

@property (nonatomic, assign) AudioBuffer recordBuffer;
@property (nonatomic, assign) AudioBufferList recordBufferList;
@property (nonatomic, assign) UInt32 recordBufferSize;

- (AudioBufferList)getBufferList:(UInt32)numberFrames;

@end

AudioStreamBasicDescription const ASAudioDescription = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
    .mChannelsPerFrame  = 1,
    .mBytesPerPacket    = 2,
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = 2,
    .mBitsPerChannel    = 16,
    .mSampleRate        = 0,
};

AudioStreamBasicDescription const ASAudioDescriptionDefaultLowQuality = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
    .mChannelsPerFrame  = 1,
    .mBytesPerPacket    = 2,
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = 2,
    .mBitsPerChannel    = 16,
    .mSampleRate        = 8000,
};

AudioStreamBasicDescription const ASAudioDescriptionDefaultHighQuality = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
    .mChannelsPerFrame  = 2,
    .mBytesPerPacket    = 4,
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = 4,
    .mBitsPerChannel    = 16,
    .mSampleRate        = 44100,
};

@implementation AudioController

#define kOutputBus 0
#define kInputBus 1

#define kDefaultRecordBufferSize    16384   // 16k record cycle buffer

#define ASBufferStackMaxFramesPerSlice 4096

#define ASCheckOSStatus(result,operation) (_ASCheckOSStatus((result),(operation),strrchr(__FILE__, '/')+1,__LINE__))
static BOOL _ASCheckOSStatus(OSStatus result, const char * _Nonnull operation, const char * _Nonnull file, int line) {
    if ( result != noErr ) {
//        if ( ASRateLimit() ) {
//            int fourCC = CFSwapInt32HostToBig(result);
//            if ( isascii(((char*)&fourCC)[0]) && isascii(((char*)&fourCC)[1]) && isascii(((char*)&fourCC)[2]) ) {
//                NSLog(@"%s:%d: %s: '%4.4s' (%d)", file, line, operation, (char*)&fourCC, (int)result);
//            } else {
//                NSLog(@"%s:%d: %s: %d", file, line, operation, (int)result);
//            }
//        }
        return NO;
    }
    return YES;
}

static OSStatus playbackCallbackFunc(void *inRefCon,
                                     AudioUnitRenderActionFlags *ioActionFlags,
                                     const AudioTimeStamp *inTimeStamp,
                                     UInt32 inBusNumber,
                                     UInt32 inNumberFrames,
                                     AudioBufferList *ioData){
    
    AudioController *unit = (__bridge AudioController* )inRefCon;
    
    OSStatus err = noErr;
    if (unit.initiallized) {
        for (int i = 0; i < ioData -> mNumberBuffers; i++) {
            @autoreleasepool {
                AudioBuffer buffer = ioData -> mBuffers[i];
                //HMLogDebug(LogModuleAudio, @"AudioUnitRender pcm data prepare fill");
                
                NSData* pcmBlock = nil;
                if (unit.delegate && [unit.delegate respondsToSelector:@selector(audioEnginePlayCallback:)]) {
                    pcmBlock = [unit.delegate audioEnginePlayCallback:buffer.mDataByteSize];
                }
                
                if (pcmBlock && pcmBlock.length) {
                    UInt32 size = (UInt32)MIN(buffer.mDataByteSize, [pcmBlock length]);
                    memcpy(buffer.mData, [pcmBlock bytes], size);
                    buffer.mDataByteSize = size;
                    //HMLogDebug(LogModuleAudio, @"AudioUnitRender pcm data has filled");
                } else {
                    buffer.mDataByteSize = 0;
                    *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
                }
            } // end pool
        } // end for
    }
    
    return err;
}

static OSStatus recordCallbackFunc(void *inRefCon,
                                   AudioUnitRenderActionFlags *ioActionFlags,
                                   const AudioTimeStamp *inTimeStamp,
                                   UInt32 inBusNumber,
                                   UInt32 inNumberFrames,
                                   AudioBufferList *ioData){
    
    AudioController *unit = (__bridge AudioController* )inRefCon;
    
    OSStatus err = noErr;
    if (unit.initiallized) {
        @autoreleasepool {
            AudioBufferList bufList = [unit getBufferList:inNumberFrames];
            err = AudioUnitRender(unit.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufList);
            if (err) {
                //HMLogDebug(LogModuleAudio, @"AudioUnitRender error code = %d", err);
            } else {
                if (unit.delegate && [unit.delegate respondsToSelector:@selector(audioEngineRecordCallback:)]) {
                    AudioBuffer buffer = bufList.mBuffers[0];
                    NSData *pcmBlock = [NSData dataWithBytes:buffer.mData length:buffer.mDataByteSize];
                    [unit.delegate audioEngineRecordCallback:pcmBlock];
                }
            }
        }
    }
    
    return err;
}

- (instancetype)init {
    if ( !(self = [super init]) ) return nil;
    
    _recordBufferSize = 16*1024;
    _recordBuffer.mNumberChannels = 1;
    _recordBuffer.mDataByteSize = _recordBufferSize;
    _recordBuffer.mData = malloc(_recordBuffer.mDataByteSize);
    _recordBufferList.mNumberBuffers = 1;
    _recordBufferList.mBuffers[0] = _recordBuffer;
    
    return self;
}

- (void)dealloc {
    [self teardown];
    
    if (_recordBuffer.mData) {
        free(_recordBuffer.mData);
    }
}

- (BOOL)setup{
    
    if (self.initiallized) {
        return YES;
    }
    
    NSError *err = nil;
    if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&err]) {
        //HMLogError(LogModuleAudio, @"AVAudioSession setPlayAndRecord failed. %@", err);
    }
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    do {
        
        // Get an instance of the output audio unit
        AudioComponentDescription description = {};
        memset(&description, 0, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Output;
        description.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
        
        AudioComponent inputComponent = AudioComponentFindNext(NULL, &description);
        OSStatus result = AudioComponentInstanceNew(inputComponent, &_audioUnit);
        if ( !ASCheckOSStatus(result, "AudioComponentInstanceNew") ) {
            //HMLogDebug(LogModuleAudio, @"Unable to instantiate IO unit");
            break;
        }
        
        // Set the maximum frames per slice to render
        UInt32 maxFramesPerSlice = ASBufferStackMaxFramesPerSlice;
        result = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global,
                                      0, &maxFramesPerSlice, sizeof(maxFramesPerSlice));
        if (!ASCheckOSStatus(result, "AudioUnitSetProperty(kAudioUnitProperty_MaximumFramesPerSlice)")){
            //HMLogDebug(LogModuleAudio, @"Unable kAudioUnitProperty_MaximumFramesPerSlice");
            break;
        }
        
        // Enable input
        UInt32 flag = 1;
        result = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &flag, sizeof(flag));
        if ( !ASCheckOSStatus(result, "AudioUnitSetProperty(kAudioOutputUnitProperty_EnableIO)") ) {
            //HMLogDebug(LogModuleAudio, @"Unable kAudioOutputUnitProperty_EnableIO");
            break;
        }
        
        // Enable output
        flag = 1;
        result = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, kOutputBus, &flag, sizeof(flag));
        if ( !ASCheckOSStatus(result, "AudioUnitSetProperty(kAudioOutputUnitProperty_EnableIO)") ) {
            //HMLogDebug(LogModuleAudio, @"Unable kAudioOutputUnitProperty_EnableIO");
            break;
        }
        
        // Set the render callback
        AURenderCallbackStruct rcbs = { .inputProc = playbackCallbackFunc, .inputProcRefCon = (__bridge void *)(self) };
        result = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, kOutputBus,
                                      &rcbs, sizeof(rcbs));
        if ( !ASCheckOSStatus(result, "AudioUnitSetProperty(kAudioUnitProperty_SetRenderCallback)") ) {
            //HMLogDebug(LogModuleAudio, @"Unable kAudioUnitProperty_SetRenderCallback");
            break;
        }
        
        // Set the input callback
        AURenderCallbackStruct inRenderProc;
        inRenderProc.inputProc = &recordCallbackFunc;
        inRenderProc.inputProcRefCon = (__bridge void *)self;
        result = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global,
                                      kOutputBus, &inRenderProc, sizeof(inRenderProc));
        if ( !ASCheckOSStatus(result, "AudioUnitSetProperty(kAudioOutputUnitProperty_SetInputCallback)") ) {
            //HMLogDebug(LogModuleAudio, @"Unable kAudioOutputUnitProperty_SetInputCallback");
            break;
        }
        
        // set buffer allocate
        flag = 0;
        result = AudioUnitSetProperty(_audioUnit,
                                      kAudioUnitProperty_ShouldAllocateBuffer,
                                      kAudioUnitScope_Output,
                                      kInputBus,
                                      &flag,
                                      sizeof(flag));
        if ( !ASCheckOSStatus(result, "AudioUnitSetProperty(kAudioUnitProperty_ShouldAllocateBuffer)") ) {
            //HMLogDebug(LogModuleAudio, @"Unable kAudioUnitProperty_ShouldAllocateBuffer");
            break;
        }
        
        // Initialize
        result = AudioUnitInitialize(_audioUnit);
        if ( !ASCheckOSStatus(result, "AudioUnitInitialize")) {
            //HMLogDebug(LogModuleAudio, @"Unable AudioUnitInitialize");
            break;
        }
        
        // Update stream format
        [self setInputAudioFormat:ASAudioDescriptionDefaultLowQuality];
        [self setOutputAudioFormat:ASAudioDescriptionDefaultLowQuality];
        
        self.initiallized = YES;
        
        return YES;
        
    } while (0);
    
    // setup failed, then clean the scene
    [self teardown];
    
    return NO;
}

- (BOOL)start{
    
    if (self.initiallized == NO) {
        return NO;
    }
    
    // Start unit
    OSStatus result = AudioOutputUnitStart(_audioUnit);
    if ( !ASCheckOSStatus(result, "AudioOutputUnitStart") ) {
        return NO;
    }
    
    return YES;
}

- (void)stop{
    
    // Stop unit
    ASCheckOSStatus(AudioOutputUnitStop(_audioUnit), "AudioOutputUnitStop");
    
    // clean up
    //[self teardown];
}

- (BOOL)running {
    if ( !_audioUnit || !self.initiallized) return NO;
    
    UInt32 unitRunning;
    UInt32 size = sizeof(unitRunning);
    if ( !ASCheckOSStatus(AudioUnitGetProperty(_audioUnit, kAudioOutputUnitProperty_IsRunning, kAudioUnitScope_Global, 0,
                                               &unitRunning, &size),
                          "AudioUnitGetProperty(kAudioOutputUnitProperty_IsRunning)") ) {
        return NO;
    }
    
    return unitRunning;
}

- (BOOL)setInputAudioFormat:(AudioStreamBasicDescription)asbd{
    if (!_audioUnit) {
        return NO;
    }
    memcpy(&_inputAudioDescription, &asbd, sizeof(_inputAudioDescription));
    ASCheckOSStatus(AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &_inputAudioDescription, sizeof(_inputAudioDescription)), "couldn't set the input client format on VoiceProcessingIO");
    
    return YES;
}

- (BOOL)setOutputAudioFormat:(AudioStreamBasicDescription)asbd{
    if (!_audioUnit) {
        return NO;
    }
    memcpy(&_outputAudioDescription, &asbd, sizeof(_outputAudioDescription));
    ASCheckOSStatus(AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputBus, &_outputAudioDescription, sizeof(_outputAudioDescription)), "couldn't set the output client format on VoiceProcessingIO");
    return YES;
}

- (AudioBufferList)getBufferList:(UInt32)numberFrames{
    
    UInt32 nNumBytesForSamples =  numberFrames*self.inputAudioDescription.mChannelsPerFrame*2;
    
    // if defaut buffer size is not enough, free old and malloc new size
    if (nNumBytesForSamples > self.recordBufferSize) {
        free(_recordBuffer.mData);
        _recordBufferSize = nNumBytesForSamples;
        _recordBuffer.mData = malloc(_recordBufferSize);
    }
    _recordBuffer.mDataByteSize = nNumBytesForSamples;
    _recordBuffer.mNumberChannels = _inputAudioDescription.mChannelsPerFrame;
    
    return _recordBufferList;
}

- (void)teardown {
    
    if (_audioUnit) {
        ASCheckOSStatus(AudioUnitUninitialize(_audioUnit), "AudioUnitUninitialize");
        ASCheckOSStatus(AudioComponentInstanceDispose(_audioUnit), "AudioComponentInstanceDispose");
        
        _audioUnit = NULL;
    }
    self.initiallized = NO;
}

@end
