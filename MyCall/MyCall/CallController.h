//
//  CallController.h
//  MyCall
//
//  Created by Mason on 2016/10/12.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>
#import "CallManager.h"


typedef void(^hasStartedConnectingDidChange)(void);
typedef void(^hasConnectedDidChange)(void);


@protocol CallControllerDelegate;

@interface CallController : NSObject

- (void)startCall:(NSString*)handle;
- (void)endCall;

- (void)startAudio;
- (void)stopAudio;

- (void)answerCall;

@property (nonatomic, strong) CallManager* callManager;

@property (nonatomic, copy) hasStartedConnectingDidChange blockStartConnecting;
@property (nonatomic, copy) hasConnectedDidChange blockConnected;

@property (nonatomic, weak) id <CallControllerDelegate> delegate;

@property (nonatomic, strong) NSDate* startConnectingDate;
@property (nonatomic, strong) NSDate* connectedDate;
@property (nonatomic, strong) NSUUID* currentUUID;
@property (nonatomic, strong) NSString* currentHandle;
@end

@protocol CallControllerDelegate <NSObject>
- (void) callStateChanged:(PhoneState)state;
@end
