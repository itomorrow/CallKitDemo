//
//  ProviderDelegate.h
//  MyCall
//
//  Created by Mason on 2016/10/11.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CallKit/CallKit.h>
#import "CallController.h"

@interface ProviderDelegate : NSObject <CXProviderDelegate>

- (instancetype)initWithCallController:(CallController*)callController;

- (void)reportIncomingCall;

@end
