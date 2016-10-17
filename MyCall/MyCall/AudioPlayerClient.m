//
//  AudioPlayer.m
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import "AudioPlayerClient.h"
#import <pthread.h>
#import "GlobalDefine.h"

@interface AudioPlayerClient ()<GCDAsyncSocketDelegate>{
    pthread_mutex_t     _lock;
}

@property (nonatomic, assign) _Nonnull id <AudioPlayerClientDelegate> delegate;

@property (nonatomic, strong) GCDAsyncSocket *socket;

@property (nonatomic, assign) AudioStreamBasicDescription audioDescription;

@property (nonatomic, strong) NSMutableData* parseData;
@property (nonatomic, strong) NSMutableData* audioData;

@end

@implementation AudioPlayerClient

- (id) initWithDelegate:(id<AudioPlayerClientDelegate>)delegate socket:(GCDAsyncSocket *)sock{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _socket = sock;
        
        _parseData = [[NSMutableData alloc] init];
        _audioData = [[NSMutableData alloc] init];
        
        pthread_mutex_init(&_lock, NULL);
        
        [_socket setDelegate:self delegateQueue:dispatch_queue_create("AudioRecvSocketQueue", NULL)];
        
        [_socket performBlock:^{
            if ([_socket enableBackgroundingOnSocket]) {
                //HMLogInfo(LogModuleAudio, @"%@ setBackground YES", self);
            } else {
                //HMLogError(LogModuleAudio, @"[%ld Play setBackground NO", self);
            }
        }];
        
        [_socket readDataWithTimeout:-1 tag:0];
    }
    return self;
}

- (void) dealloc {
    
    pthread_mutex_destroy(&_lock);
    
    if (self.socket) {
        [self.socket setDelegate:nil];
        
        if (self.socket.isConnected) {
            [self.socket disconnect];
        }
    }
}

- (NSData*)readAudioData:(NSInteger)maxLength{
    NSData* dataResult = NULL;
    
    if (!self.isRunning) {
        return NULL;
    }
    
    pthread_mutex_lock(&_lock);
    
    @autoreleasepool {
        long length = self.audioData ? self.audioData.length:0;
        if (length) {
            UInt32 bufferLen = (UInt32)MIN(maxLength, length);
            NSData *data = [NSData dataWithData:[self.audioData subdataWithRange:NSMakeRange(0, bufferLen)]];
#ifdef DUMP_AUDIO_PLAY_STREAM
            HMLogDebug(LogModuleAudio, @"getNextPlayFrame has data length = %ld", data.length);
#endif
            dataResult = data;
            
            [self.audioData replaceBytesInRange:NSMakeRange(0, bufferLen) withBytes:NULL length:0];
            pthread_mutex_unlock(&_lock);
            return dataResult;
        } else {
#ifdef DUMP_AUDIO_PLAY_STREAM
            HMLogDebug(LogModuleAudio, @"getNextPlayFrame has data length = 0");
#endif
        }
    }
    
    pthread_mutex_unlock(&_lock);
    
    return NULL;
}

- (void)parsePacket:(NSData*)data{
    
    if (!data || data.length==0) return;
    
    [self.parseData appendData:data];
    
    long dataLength = data.length;
    int cmd = 0;
    int packLength = 0;
    int audioHeaderLength = 0;
    
    while (dataLength >= sizeof(UInt32)*2) {
        @autoreleasepool {
            [self.parseData getBytes:&cmd range:NSMakeRange(0, sizeof(UInt32))];
            [self.parseData getBytes:&packLength range:NSMakeRange(sizeof(UInt32), sizeof(UInt32))];
            
            if (dataLength < packLength) {
                break;
            }
            
            if (cmd == ASPhoneCommandTypeAccept) {
                [self.delegate AudioPlayerClientAccept:self];
                NSLog(@"accept command received");
            } else if (cmd == ASPhoneCommandTypeData) {
                audioHeaderLength = sizeof(UInt32)*2;
                if (_isRunning && packLength > audioHeaderLength) {
                    NSData *audioData = [self.parseData subdataWithRange:NSMakeRange(audioHeaderLength, packLength-audioHeaderLength)];
                    [self.audioData appendData:audioData];
                }
            }
        }// end releasepool
        [self.parseData replaceBytesInRange:NSMakeRange(0, packLength) withBytes:NULL length:0];
        dataLength = self.parseData.length;
    }// end while
}

#pragma mark - GCDAsyncSocketDelegate
- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    //HMLogDebug(LogModuleAudio, @"[%ld Play %@] didDisconnect %@", self, self.playTypeString, err.localizedDescription);
    //[self stopPlay];
    self.isRunning = NO;
    //[self.delegate AudioPlayerClientStop:self];
}

- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    pthread_mutex_lock(&_lock);
    [self parsePacket:data];
    pthread_mutex_unlock(&_lock);
    
    [sock readDataWithTimeout:-1 tag:0];
}

@end
