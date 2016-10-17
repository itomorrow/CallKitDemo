//
//  AudioPlayer.h
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudioKit/CoreAudioKit.h>
#import "GCDAsyncSocket.h"

@protocol AudioPlayerDelegate;

@interface AudioPlayer : NSObject
- (id) initWithDelegate:(id<AudioPlayerDelegate>)delegate socket:(GCDAsyncSocket *)sock;
- (NSData*)readAudioData:(NSInteger)maxLength;

- (void)acceptCall;

@property (nonatomic, assign) BOOL isRunning;
@end

@protocol AudioPlayerDelegate <NSObject>
- (void) audioPlayerStop:(AudioPlayer *)player;
@end
