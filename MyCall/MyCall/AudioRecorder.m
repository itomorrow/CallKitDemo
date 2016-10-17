//
//  AudioRecorder.m
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import "AudioRecorder.h"
#import "GCDAsyncSocket.h"
#import <pthread.h>
#import "GlobalDefine.h"

@interface AudioRecorder ()<GCDAsyncSocketDelegate>{
    pthread_mutex_t     _lock;
}


@property (nonatomic, assign) _Nonnull id <AudioRecorderDelegate> delegate;

@property (nonatomic, strong) GCDAsyncSocket *socket;

@property (nonatomic, assign) AudioStreamBasicDescription audioDescription;

@property (nonatomic, strong) NSMutableData* parseData;

@property (nonatomic, assign) BOOL initialized;

@end



@implementation AudioRecorder

- (id) initWithDelegate:(id<AudioRecorderDelegate>)delegate socket:(GCDAsyncSocket *)sock{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _socket = sock;
        
        _parseData = [[NSMutableData alloc] init];
        
        pthread_mutex_init(&_lock, NULL);
        
        [_socket setDelegate:self delegateQueue:dispatch_queue_create("AudioSendSocketQueue", NULL)];
        
        [_socket performBlock:^{
            if ([_socket enableBackgroundingOnSocket]) {
                //HMLogInfo(LogModuleAudio, @"%@ setBackground YES", self);
            } else {
                //HMLogError(LogModuleAudio, @"[%ld record setBackground NO", self);
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

- (void)acceptCall{
    UInt32 cmd = ASPhoneCommandTypeAccept;
    UInt32 length = sizeof(UInt32)*2;
    NSMutableData* acceptCmd = [NSMutableData dataWithBytes:&cmd length:sizeof(cmd)];
    [acceptCmd appendBytes:&length length:sizeof(UInt32)];
    [self.socket writeData:acceptCmd withTimeout:-1 tag:0];
}

- (void)writeAudioData:(NSData*)audioData{
    
    if (!self.socket.isConnected || !self.isRunning) {
        return;
    }
    
    if (!audioData || audioData.length==0 || !self.socket || !self.socket.isConnected) {
        //HMLogDebug(LogModuleAudio, @"[%ld Record] didRecordData Returned NO-Data.", self);
        return;
    }
    
    UInt32 cmd = ASPhoneCommandTypeData;
    UInt32 length = (UInt32)audioData.length + sizeof(UInt32)*2;
    NSMutableData* dataToSend = [NSMutableData dataWithBytes:&cmd length:sizeof(UInt32)];
    [dataToSend appendBytes:&length length:sizeof(UInt32)];
    [dataToSend appendData:audioData];
    
    [self.socket writeData:dataToSend withTimeout:-1 tag:0];
}


#pragma mark - GCDAsyncSocketDelegate
- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    //HMLogDebug(LogModuleAudio, @"[%ld Record] didDisconnect %@", self, err.localizedDescription);
    //[self stopRecord];
    self.isRunning = NO;
    [self.delegate audioRecorderStop:self];
}

- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    [sock readDataWithTimeout:-1 tag:0];
}

@end
