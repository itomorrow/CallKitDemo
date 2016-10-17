//
//  MycallManagerManager.h
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GlobalDefine.h"
#import "AudioController.h"

@protocol CallManagerDelegate;

@interface CallManager : NSObject<AudioControllerDelegate>

- (void)startCall:(NSString*)address;
- (void)stopCall;
- (void)acceptCall;

@property (nonatomic, assign) BOOL isOutgoingCall;

@property (nonatomic, assign) PhoneState state;
@property (nonatomic, copy) NSString* currentHandle;

@property (nonatomic, weak) id <CallManagerDelegate> delegate;

@end


@protocol CallManagerDelegate <NSObject>
- (void) callStateChanged;
@end
