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

@protocol AudioPlayerClientDelegate;

@interface AudioPlayerClient : NSObject
- (id) initWithDelegate:(id<AudioPlayerClientDelegate>)delegate socket:(GCDAsyncSocket *)sock;
- (NSData*)readAudioData:(NSInteger)maxLength;
@property (nonatomic, assign) BOOL isRunning;
@end

@protocol AudioPlayerClientDelegate <NSObject>
- (void) AudioPlayerClientAccept:(AudioPlayerClient *)player;
//- (void) AudioPlayerClientStop:(AudioPlayerClient *)player;
@end
