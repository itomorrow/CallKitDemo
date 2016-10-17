//
//  GCDAsyncListenSocket.h
//  MyCall
//
//  Created by Apple on 16/4/20.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import "GCDAsyncSocket.h"

@interface GCDAsyncListenSocket : GCDAsyncSocket

- (id) initWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq;

- (BOOL) start:(uint16_t)port error:(NSError **)errPtr;
- (void) stop;

@end
