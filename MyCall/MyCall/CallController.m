//
//  CallController.m
//  MyCall
//
//  Created by Mason on 2016/10/12.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import "CallController.h"

@interface CallController ()<CallManagerDelegate>

@property (nonatomic, strong) CXCallController* callController;

@property (nonatomic, strong) AudioController* audioController;

@property (nonatomic, assign) PhoneState state;

@end

@implementation CallController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _callController = [[CXCallController alloc] init];
        _callManager = [[CallManager alloc] init];
        _callManager.delegate = self;
        
        _audioController = [[AudioController alloc] init];
        [_audioController setDelegate:self.callManager];
        [_audioController setup];
    }
    return self;
}

- (void)startCall:(NSString*)handle{
    self.currentUUID = [NSUUID UUID];
    self.startConnectingDate = [NSDate date];
    self.currentHandle = handle;
#ifdef USE_CALLKIT
    CXHandle* handleNumber = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:handle];
    CXStartCallAction* action = [[CXStartCallAction alloc] initWithCallUUID:self.currentUUID handle:handleNumber];
    action.video = NO;
    CXTransaction* transaction = [[CXTransaction alloc] init];
    [transaction addAction:action];
    [self requestTransaction:transaction];
#else
    [self.callManager startCall:handle];
#endif
}

- (void)endCall{
#ifdef USE_CALLKIT
    CXEndCallAction* endAction = [[CXEndCallAction alloc] initWithCallUUID:self.currentUUID];
    CXTransaction* transaction = [[CXTransaction alloc] init];
    [transaction addAction:endAction];
    [self requestTransaction:transaction];
#else
    [self.callManager stopCall];
#endif
}

- (void)startAudio{
    [self.audioController start];
}

- (void)stopAudio{
    [self.audioController stop];
}

- (void)answerCall{
    [self.callManager acceptCall];
}

- (void)requestTransaction:(CXTransaction*)transaction{
    [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"requestTransaction error %@", error);
        }
    }];
}

#pragma mark - CallManagerDelegate
- (void) callStateChanged{
    
    if (self.callManager.state == self.state) {
        return;
    }
    
    if (self.callManager.state == PhoneStateConnected) {
        self.connectedDate = [NSDate date];
    }
    if (self.callManager.state == phoneStateConnectingFrom) {
        self.currentUUID = [NSUUID UUID];
        self.currentHandle = @"15810699821";
    }
    
    if (self.delegate) {
        [self.delegate callStateChanged:self.callManager.state];
    }
    
#ifdef USE_CALLKIT

    // notify callkit UI connecting date
    if (self.callManager.state == PhoneStateConnectingTo){
        if (self.blockStartConnecting) self.blockStartConnecting();
    }
    
    // notify callkit UI connected date
    if (self.callManager.state == PhoneStateConnected)
        self.connectedDate = [NSDate date];
        if (self.blockConnected)self.blockConnected();
    
    if (self.callManager.state == PhoneStateNoneTo ||
        self.callManager.state == PhoneStateNoneFrom) {
        [self endCall];
    } 
#else
    if (self.callManager.state == PhoneStateConnected) {
        [self startAudio];
    } else if (self.callManager.state == PhoneStateNoneTo |
               self.callManager.state == PhoneStateNoneFrom) {
        [self stopAudio];
    }
#endif

    self.state = self.callManager.state;
}


@end
