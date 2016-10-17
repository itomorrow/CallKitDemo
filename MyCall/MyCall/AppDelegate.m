//
//  AppDelegate.m
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFAudio.h>
#import <PushKit/PushKit.h>
#import "RootViewController.h"
#import "ProviderDelegate.h"
#import "AudioController.h"
#import "CallManager.h"
#import "GlobalDefine.h"

@interface AppDelegate ()<PKPushRegistryDelegate, CallControllerDelegate>

@property (nonatomic, strong) RootViewController* root;

@property (nonatomic, strong) PKPushRegistry* pushRegistry;

@property(nonatomic, strong) CallController* callController;
@property (nonatomic, strong) ProviderDelegate* provider;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    self.pushRegistry.delegate = self;
    self.pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    
    self.root = [[RootViewController alloc] init];
    self.window.rootViewController = self.root;
    
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        
    }];
    
    _callController = [[CallController alloc] init];
    _callController.delegate = self;

    self.provider = [[ProviderDelegate alloc] initWithCallController:_callController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserStartCall:) name:NOTIFICATION_STARTCALL object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserAnswerCall) name:NOTIFICATION_ANSWERCALL object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserEndCall) name:NOTIFICATION_ENDCALL object:nil];
    
    return YES;
}

- (void)onUserStartCall:(NSNotification*)notification{
    NSString* handle = notification.object;
    [self.callController startCall:handle];
}

- (void)onUserAnswerCall{
    [self.callController answerCall];
}

- (void)onUserEndCall{
    [self.callController endCall];
}

#pragma makr - CallControllerDelegate
- (void) callStateChanged:(PhoneState)state{
    
    [self.root updatePhoneState:state];
    
    if (state == PhoneStateConnected) {
        [self.root updateConnectedDate:self.callController.connectedDate];
    }
    
#ifdef USE_CALLKIT
    // display incoming call UI
    if (state == phoneStateConnectingFrom) {
        [self.provider reportIncomingCall];
    }
#endif
}

#pragma mark - PKPushRegistryDelegate
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type{
    /*
     Store push credentials on server for the active user.
     For sample app purposes, do nothing since everything is being done locally.
     */
    
    if([credentials.token length] == 0)
    {
        NSLog(@"voip token NULL");
        return;
    }
    
//    ZeroPush * push = [[ZeroPush alloc] init];
//    
//    // push.apiKey = @"iosdev_1Z6JR3PKBWrAWbuHLbLQ";
//    
//    push.apiKey = @"iosprod_HZDimW5ssYsRQgaSaEoE";
//    
//    // iosprod_HZDimW5ssYsRQgaSaEoE
//    
//    [push registerDeviceToken:credentials.token channel:@"me"];
}


- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type{
    
    NSLog(@"didReceiveIncomingPushWithPayload");
    // 此时进行voip注册
    
    // write your voip related codes here
    
//    UIUserNotificationType theType = [UIApplication sharedApplication].currentUserNotificationSettings.types;
//    if (theType == UIUserNotificationTypeNone)
//    {
//        UIUserNotificationSettings *userNotifySetting = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert categories:nil];
//        [[UIApplication sharedApplication] registerUserNotificationSettings:userNotifySetting];
//    }
//    
//    
//    UILocalNotification *backgroudMsg = [[UILocalNotification alloc] init];
//    backgroudMsg.alertBody= @"You receive a new call";
//    [[UIApplication sharedApplication] presentLocalNotificationNow:backgroudMsg];
    
    
//    guard type == .voIP else { return }
//    
//    if let uuidString = payload.dictionaryPayload["UUID"] as? String,
//        let handle = payload.dictionaryPayload["handle"] as? String,
//        let hasVideo = payload.dictionaryPayload["hasVideo"] as? Bool,
//        let uuid = UUID(uuidString: uuidString)
//    {
//        displayIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo)
//    }
}

@end
