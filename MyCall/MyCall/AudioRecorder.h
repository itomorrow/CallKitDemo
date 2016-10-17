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

@protocol AudioRecorderDelegate;

@interface AudioRecorder : NSObject
- (id) initWithDelegate:(id<AudioRecorderDelegate>)delegate socket:(GCDAsyncSocket *)sock;

- (void)writeAudioData:(NSData*)audioData;
@property (nonatomic, assign) BOOL isRunning;

- (void)acceptCall;

@end


@protocol AudioRecorderDelegate <NSObject>
- (void) audioRecorderStop:(AudioRecorder *)recorder;
@end
