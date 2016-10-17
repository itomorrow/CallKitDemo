//
//  ProviderDelegate.m
//  MyCall
//
//  Created by Mason on 2016/10/11.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import "ProviderDelegate.h"
#import "GlobalDefine.h"

@interface ProviderDelegate ()

@property (nonatomic, strong) CXProvider* provider;

@property (nonatomic, readonly) CXProviderConfiguration* config;

@property (nonatomic, weak) CallController* callController;
@end

@implementation ProviderDelegate

- (CXProviderConfiguration *)config{
    static CXProviderConfiguration* configInternal = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        configInternal = [[CXProviderConfiguration alloc] initWithLocalizedName:@"MyCall"];
        configInternal.supportsVideo = NO;
        configInternal.maximumCallsPerCallGroup = 1;
        configInternal.maximumCallGroups = 1;
        configInternal.supportedHandleTypes = [NSSet setWithObject:@(CXHandleTypePhoneNumber)];
        UIImage* iconMaskImage = [UIImage imageNamed:@"IconMask"];
        configInternal.iconTemplateImageData = UIImagePNGRepresentation(iconMaskImage);
        configInternal.ringtoneSound = @"Ringtone.caf";
    });
    
    return configInternal;
}

- (instancetype)initWithCallController:(CallController*)callController{
    self = [super init];
    if (self) {
        self.callController = callController;
        _provider = [[CXProvider alloc] initWithConfiguration:self.config];
        [_provider setDelegate:self queue:nil];
    }
    
    return self;
}

- (void)reportIncomingCall{

    CXCallUpdate* update = [[CXCallUpdate alloc] init];
    update.hasVideo = NO;
    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:self.callController.currentHandle];
    
    [self.provider reportNewIncomingCallWithUUID:self.callController.currentUUID update:update completion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"report error");
        }
    }];
}


#pragma mark - CXProviderDelegate
/// Called when the provider has been reset. Delegates must respond to this callback by cleaning up all internal call state (disconnecting communication channels, releasing network resources, etc.). This callback can be treated as a request to end all calls without the need to respond to any actions
- (void)providerDidReset:(CXProvider *)provider{

    [self.callController stopAudio];
    
    [self.callController endCall];

}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action{

    NSUUID* currentID = self.callController.currentUUID;
    if ([[action.callUUID UUIDString] isEqualToString:[currentID UUIDString]]) {
        
        __weak ProviderDelegate* weakSelf = self;
        self.callController.blockStartConnecting = ^(void){
            [weakSelf.provider reportOutgoingCallWithUUID:currentID startedConnectingAtDate:weakSelf.callController.connectedDate];
            NSLog(@"connecting");
        };
        
        self.callController.blockConnected = ^(void){
            [weakSelf.provider reportOutgoingCallWithUUID:currentID connectedAtDate:weakSelf.callController.connectedDate];
            NSLog(@"connected");
            
        };
        
        [self.callController.callManager startCall:self.callController.currentHandle];
        
        [action fulfill];
    } else {
        [action fail];
    }
}

// user answered this incoming call
- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action{

    NSUUID* currentID = self.callController.currentUUID;
    if ([[action.callUUID UUIDString] isEqualToString:[currentID UUIDString]]) {
        [self.callController answerCall];
        [action fulfill];
    } else {
        [action fail];
    }

}

// user end this call
- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action{
    
    NSUUID* currentID = self.callController.currentUUID;
    if ([[action.callUUID UUIDString] isEqualToString:[currentID UUIDString]]) {
        [self.callController stopAudio];
        [self.callController.callManager stopCall];
        [action fulfill];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession{
    [self.callController startAudio];
    NSLog(@"session has activate");
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession{

}

@end
