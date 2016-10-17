//
//  GCDAsyncSocket+Listen.m
//  MyCall
//
//  Created by Apple on 16/4/20.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import "GCDAsyncListenSocket.h"

@interface GCDAsyncListenSocket ()

@property (nonatomic, assign) BOOL isListening;

@end

@implementation GCDAsyncListenSocket

- (id)initWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq {
    if (self = [super initWithDelegate:aDelegate delegateQueue:dq]) {
        self.isListening = NO;
    }
    
    return self;
}

- (BOOL) start:(uint16_t)port error:(NSError **)errPtr {
    if (self.isListening) return YES;
    
    [super disconnect];
    
    self.isListening = [super acceptOnPort:port error:errPtr];
    
    return self.isListening;
}

- (void) stop {
    [super disconnect];
    
    self.isListening = NO;
}

@end
