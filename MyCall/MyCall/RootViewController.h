//
//  RootViewController.h
//  MyCall
//
//  Created by Mason on 2016/10/11.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallController.h"

@interface RootViewController : UIViewController

- (void) updatePhoneState:(PhoneState)state;

- (void) updateConnectedDate:(NSDate*)date;

@end
