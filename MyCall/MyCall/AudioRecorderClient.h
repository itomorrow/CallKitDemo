//
//  AudioRecorder.h
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudioKit/CoreAudioKit.h>
#import "GCDAsyncSocket.h"

@protocol AudioRecorderClientDelegate;

@interface AudioRecorderClient : NSObject
- (id) initWithDelegate:(id<AudioRecorderClientDelegate>)delegate socket:(GCDAsyncSocket *)sock;

- (void)writeAudioData:(NSData*)audioData;
@property (nonatomic, assign) BOOL isRunning;
@end


@protocol AudioRecorderClientDelegate <NSObject>
- (void) AudioRecorderClientStop:(AudioRecorderClient *)recorder;
@end
