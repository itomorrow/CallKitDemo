//
//  CallManager.m
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import "CallManager.h"
#import <CallKit/CallKit.h>

#import "AudioPlayer.h"
#import "AudioRecorder.h"

#import "AudioPlayerClient.h"
#import "AudioRecorderClient.h"

#import "GCDAsyncSocket.h"
#import "GCDAsyncListenSocket.h"


#define AS_Android_AudioSendPort        55900           //录音数据发送端口
#define AS_Android_AudioRecvPort        55901           //声音数据接收端口


@interface CallManager()<GCDAsyncSocketDelegate, AudioPlayerDelegate, AudioRecorderDelegate, AudioPlayerClientDelegate, AudioRecorderClientDelegate>


@property (nonatomic, strong) AudioPlayer* currentPlayer;
@property (nonatomic, strong) AudioRecorder* currentRecorder;

@property (nonatomic, strong) GCDAsyncListenSocket *recvSocket;
@property (nonatomic, strong) GCDAsyncListenSocket *sendSocket;

@property (nonatomic, strong) GCDAsyncSocket* recvClientSocket;
@property (nonatomic, strong) GCDAsyncSocket* sendClientSocket;

@property (nonatomic, strong) AudioPlayerClient* currentClientPlayer;
@property (nonatomic, strong) AudioRecorderClient* currentClientRecorder;

@end

@implementation CallManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _recvSocket = [[GCDAsyncListenSocket alloc] initWithDelegate:self
                                                       delegateQueue:dispatch_queue_create("AudioRecvSocketQueue", NULL)];
        [_recvSocket enableBackgroundingOnSocket];
        
        _sendSocket = [[GCDAsyncListenSocket alloc] initWithDelegate:self
                                                       delegateQueue:dispatch_queue_create("AudioSendSocketQueue", NULL)];
        [_sendSocket enableBackgroundingOnSocket];
        
        [self startSocketServer];
    }
    return self;
}

- (void)dealloc{
    [self stopSocketClient];
    [self stopSocketServer];
}

- (void)startCall:(NSString*)address{
    self.currentHandle = address;
    self.isOutgoingCall = YES;
    [self startSocketClient];
}

- (void)acceptCall{
    
    if (self.state != phoneStateConnectingFrom) {
        return;
    }
    
    if (self.currentPlayer) {
        [self.currentRecorder acceptCall];
        [self resetToConnected];
    }
}

- (void)stopCall{
    if (self.isOutgoingCall) {
        [self stopSocketClient];
    }
    
    [self resetToEndCall];
}

#pragma mark - server socket
- (void) startSocketServer {
    NSError *err = nil;
    
    if ([self.recvSocket start:AS_Android_AudioRecvPort error:&err]) {
    }

    if ([self.sendSocket start:AS_Android_AudioSendPort error:&err]) {
    }
}

- (void) stopSocketServer {
    
    if (self.recvSocket) {
        [self.recvSocket stop];
    }
    
    if (self.sendSocket) {
        [self.sendSocket stop];
    }
}

#pragma mark - client socket
- (void) startSocketClient {
    NSError *err = nil;
    self.sendClientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("AudioSendSocketClientQueue", NULL)];
    
    BOOL resutl = [self.sendClientSocket connectToHost:self.currentHandle onPort:AS_Android_AudioSendPort error:&err];
    if (resutl == NO || err != nil) {
        NSLog(@"connect host error");
    }
    
    self.recvClientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("AudioRecvSocketClientQueue", NULL)];
    
    [self.recvClientSocket connectToHost:self.currentHandle onPort:AS_Android_AudioRecvPort error:&err];
    if (resutl == NO || err != nil) {
        NSLog(@"connect host error");
    }
}

- (void) stopSocketClient {
    
    if (self.recvClientSocket) {
        [self.recvClientSocket setDelegate:nil];
        [self.recvClientSocket disconnect];
        self.recvClientSocket = nil;
    }
    
    if (self.sendClientSocket) {
        [self.sendClientSocket setDelegate:nil];
        [self.sendClientSocket disconnect];
        self.sendClientSocket = nil;
    }
}


#pragma mark - GCDAsyncSocketDelegate for call in
- (void) socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    
    if (sock == self.recvSocket) {
        AudioPlayer *player = [[AudioPlayer alloc] initWithDelegate:self socket:newSocket];
        if (player) {
            self.currentPlayer = player;
            //HMLogInfo(LogModuleAudio, @"player AccpetNewSocket %@.", player);
        }
        
    } else if (sock == self.sendSocket) {
        AudioRecorder *recorder = [[AudioRecorder alloc] initWithDelegate:self socket:newSocket];
        if (recorder) {
            self.currentRecorder = recorder;
            //HMLogInfo(LogModuleAudio, @"recv AccpetNewSocket %@.", recorder);
        }
    }
    
    // has incoming call
    if (self.currentPlayer && self.currentRecorder) {
        [self resetToConnectingFrom];
    }
}

#pragma mark - GCDAsyncSocketDelegate for call out
- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    //HMLogInfo(LogModuleAudio, @"Socket %@ Disconnect %@", sock, err);
    if (sock == self.recvClientSocket) {
        self.recvClientSocket = nil;
    }
    
    if (sock == self.sendClientSocket) {
        self.sendClientSocket = nil;
    }
    
    if (nil == self.recvClientSocket && nil == self.sendClientSocket) {
        [self resetToEndCall];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{

    if (sock == self.sendClientSocket) {
        AudioPlayerClient *player = [[AudioPlayerClient alloc] initWithDelegate:self socket:sock];
        self.currentClientPlayer = player;

        NSLog(@"client player connected server!");
    } else if (sock == self.recvClientSocket){
        AudioRecorderClient* recorder = [[AudioRecorderClient alloc] initWithDelegate:self socket:sock];
        self.currentClientRecorder = recorder;
        NSLog(@"client recorder connected server!");
    }
    
    //has outgoing call (connecting)
    if (self.currentClientPlayer && self.currentClientRecorder) {
        [self resetToConnectingTo];
    }
}

#pragma mark - AudioPlayerDelegate
- (void) audioPlayerStop:(AudioPlayer *)player{
    [self resetToEndCall];
}

#pragma mark - AudioRecorderDelegate
- (void) audioRecorderStop:(AudioRecorder *)recorder{
    [self resetToEndCall];
}

#pragma mark - AudioPlayerClientDelegate
- (void) AudioPlayerClientAccept:(AudioPlayerClient *)player{
    // has outgoing call (connected)
    [self resetToConnected];
}

- (void) AudioPlayerClientStop:(AudioPlayerClient *)player{
    [self resetToEndCall];
}

#pragma mark - AudioRecorderClientDelegate
- (void) AudioRecorderClientStop:(AudioRecorderClient *)recorder{
    [self resetToEndCall];
}

#pragma mark - AudioControllerDelegate
/*!
 * callback function, when engine running, engine pull play data from you
 */
- (NSData* _Nonnull)audioEnginePlayCallback:(NSInteger)length{
    if (!self.isOutgoingCall) {
        if (self.currentPlayer&&self.currentPlayer.isRunning) {
            return [self.currentPlayer readAudioData:length];
        }
    } else {
        if (self.currentClientPlayer && self.currentClientPlayer.isRunning) {
            return [self.currentClientPlayer readAudioData:length];
        }
    }
    return NULL;
}

/*!
 * callback function, when engine running, engine push record data to you
 */
- (void)audioEngineRecordCallback:(NSData* _Nonnull)audioBuffer{
    if (!self.isOutgoingCall) {
        if (self.currentRecorder&&self.currentRecorder.isRunning) {
            [self.currentRecorder writeAudioData:audioBuffer];
        }
    } else {
        if (self.currentClientRecorder&&self.currentClientRecorder.isRunning) {
            [self.currentClientRecorder writeAudioData:audioBuffer];
        }
    }
}

#pragma makr - phone state switch
- (void)resetToEndCall{
    
    if (self.state != PhoneStateNoneTo &&
        self.state != PhoneStateNoneFrom) {
        
        if (self.isOutgoingCall) {
            self.state = PhoneStateNoneTo;
            self.currentClientRecorder = nil;
            self.currentClientPlayer = nil;
        } else {
            self.state = PhoneStateNoneFrom;
            self.currentPlayer = nil;
            self.currentRecorder = nil;
        }
        
        self.isOutgoingCall = NO;
        self.currentHandle = nil;
        
        [self.delegate callStateChanged];
    }
}

- (void)resetToConnected{
    if (self.state != PhoneStateConnected) {
        self.state = PhoneStateConnected;
        
        [self.delegate callStateChanged];
        
        if (self.isOutgoingCall){
            self.currentClientRecorder.isRunning = YES;
            self.currentClientPlayer.isRunning = YES;
        } else {
            self.currentRecorder.isRunning = YES;
            self.currentPlayer.isRunning = YES;
        }

    }
}

- (void)resetToConnectingTo{
    if (self.state != PhoneStateConnectingTo) {
        self.state = PhoneStateConnectingTo;
        [self.delegate callStateChanged];
    }
}

- (void)resetToConnectingFrom{
    if (self.state != phoneStateConnectingFrom) {
        self.state = phoneStateConnectingFrom;
        [self.delegate callStateChanged];
    }
}


@end
