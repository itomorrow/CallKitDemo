//
//  ViewController.m
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import "RootViewController.h"

#import "GlobalDefine.h"

#import <ifaddrs.h>
#import <arpa/inet.h>


@interface RootViewController ()
@property(nonatomic, strong) UITextField* phoneAddress;
@property(nonatomic, strong) UITextField* phonePort;
@property(nonatomic, strong) UILabel* phoneState;
@property(nonatomic, strong) UILabel* myAddress;

@property (nonatomic, strong) NSTimer* callDurationTimer;

@property (nonatomic, strong) NSDate* connectedDate;

@property(nonatomic, strong) UIButton* getCall;
@property(nonatomic, strong) UIButton* shutdownCall;

@property (nonatomic, assign) BOOL isWait;

@property (nonatomic, assign) PhoneState state;

@property (nonatomic, strong) NSDateComponentsFormatter* formatter;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.formatter = [[NSDateComponentsFormatter alloc] init];
    self.formatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
    self.formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    self.formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    
    self.phoneState = [[UILabel alloc] init];
    self.phoneState.frame = CGRectMake(self.view.bounds.size.width/2 - 500/2, 50, 500, 40);
    self.phoneState.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.phoneState];
    
    self.myAddress = [[UILabel alloc] init];
    self.myAddress.frame = CGRectMake(self.view.bounds.size.width/2 - 500/2, 120, 500, 40);
    self.myAddress.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.myAddress];
    
    NSString* add = [self getIpAddresses];
    self.myAddress.text = [NSString stringWithFormat:@"my number: %@", add];
    
    self.phoneAddress = [[UITextField alloc] init];
    self.phoneAddress.frame = CGRectMake(self.view.bounds.size.width/2- 300/2, 200, 300, 40);
    self.phoneAddress.textAlignment = NSTextAlignmentCenter;
    self.phoneAddress.placeholder = @"对方IP地址";
    self.phoneAddress.borderStyle = UITextBorderStyleLine;
    //self.phoneAddress.text = number;
    [self.view addSubview:self.phoneAddress];
    
    self.getCall = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.getCall.frame = CGRectMake(self.view.bounds.size.width/2 - 200/2, 260, 200, 80);
    [self.getCall setTitle:@"开始呼叫" forState:UIControlStateNormal];
    self.getCall.titleLabel.font = [UIFont boldSystemFontOfSize:26.0];
    [self.getCall addTarget:self action:@selector(onGetCall) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.getCall];
    
    self.shutdownCall = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.shutdownCall.frame = CGRectMake(self.view.bounds.size.width/2 - 200/2, 380, 200, 80);
    [self.shutdownCall addTarget:self action:@selector(onShutdownCall) forControlEvents:UIControlEventTouchUpInside];
    self.shutdownCall.titleLabel.font = [UIFont boldSystemFontOfSize:26.0];
    [self.shutdownCall setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.shutdownCall setTitle:@"挂断" forState:UIControlStateNormal];
    [self.view addSubview:self.shutdownCall];
    
    [self updatePhoneState:PhoneStateNoneTo];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onGetCall{
    if (self.state == PhoneStateNoneTo || self.state == PhoneStateNoneFrom) {
        NSString* add = self.phoneAddress.text;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STARTCALL object:add];
    } else if (self.state == phoneStateConnectingFrom){
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ANSWERCALL object:nil];
    }
}

- (void)onShutdownCall{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ENDCALL object:nil];
}

- (void)updatePhoneStateUI:(PhoneState)newState{
    
    if (newState == PhoneStateNoneTo || newState == PhoneStateNoneFrom) {
        
        
        [self updateCallDurationTimer];
        
        self.phoneState.text = @"待机中";
        
        [self.getCall setTitle:@"呼叫" forState:UIControlStateNormal];
        
        self.getCall.hidden = NO;
        self.shutdownCall.hidden = YES;
        
        
        
    } else if (newState == phoneStateConnectingFrom){
        
        self.phoneState.text = @"来电中";
        
        [self.getCall setTitle:@"接听" forState:UIControlStateNormal];
        
        self.getCall.hidden = NO;
        self.shutdownCall.hidden = NO;
        
    } else if (newState == PhoneStateConnectingTo){
        
        self.phoneState.text = @"呼叫中";
        
        self.getCall.hidden = YES;
        self.shutdownCall.hidden = NO;
        
    } else if (newState == PhoneStateConnected){
        
        [self updateCallDurationTimer];
        
        self.shutdownCall.hidden = NO;
        self.getCall.hidden = YES;
    }
}

- (void)updateCallDurationTimer{
    
    if (self.callDurationTimer == nil && self.state == PhoneStateConnected) {
        self.callDurationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(callDuraionTimerFired) userInfo:nil repeats:YES];
    } else if ((self.state == PhoneStateNoneTo || self.state == PhoneStateNoneFrom) && self.callDurationTimer != nil) {
        [self.callDurationTimer invalidate];
        self.callDurationTimer = nil;
    }
}

- (void)callDuraionTimerFired{
    NSTimeInterval duration = ([NSDate date].timeIntervalSince1970 - self.connectedDate.timeIntervalSince1970);
    NSString* durationString = [self.formatter stringFromTimeInterval:duration];
    __weak RootViewController* weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.phoneState.text = durationString;
    });
}


- (void) updatePhoneState:(PhoneState)state{
    self.state = state;
    __weak RootViewController* weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf updatePhoneStateUI:self.state];
    });
    
}

- (void) updateConnectedDate:(NSDate*)date{
    self.connectedDate = date;
}

- (NSString *)getIpAddresses{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}


@end
