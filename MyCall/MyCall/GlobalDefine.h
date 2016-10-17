//
//  GlobalDefine.h
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#ifndef TypeDefine_h
#define TypeDefine_h


#import "AppDelegate.h"

// Comment this line to shut down callkit ability
#define USE_CALLKIT



// Default data for debug,no need to input address every debuging
//#define MYPHONE

#define PhoneNumberOne @"172.16.0.134";
#define PhoneNumberTwo @"172.16.0.252";

#ifdef MYPHONE
#define number PhoneNumberOne
#else
#define number PhoneNumberTwo
#endif



// Notification for UI Action
#define NOTIFICATION_STARTCALL             @"Notification_StartCall"
#define NOTIFICATION_ANSWERCALL             @"Notification_AnswerCall"
#define NOTIFICATION_ENDCALL                @"Notification_EndCall"


// Phone state enum
typedef NS_ENUM(NSUInteger, PhoneState) {
    PhoneStateNoneTo,
    PhoneStateNoneFrom,
    PhoneStateConnectingTo,
    phoneStateConnectingFrom,
    PhoneStateConnected,
    PHoneStateDisconnect,
};

// Phone commands
typedef NS_ENUM(UInt32, ASPhoneCommandType) {
    //Command
    ASPhoneCommandTypeRefuse      = 0x01, //
    ASPhoneCommandTypeAccept   = 0x2, //
    ASPhoneCommandTypeData   = 0x03, //
};


#endif /* TypeDefine_h */
