//
//  AudioController.h
//  MyCall
//
//  Created by Mason on 2016/10/9.
//  Copyright © 2016年 Mason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudioKit/CoreAudioKit.h>

@protocol AudioControllerDelegate;

@interface AudioController : NSObject

/*!
 * Setup the audio engine, abstract
 *
 *  Call this after alloc the instance to initialize it, prior to calling start:.
 *
 * @return YES on success, NO on failure
 */
- (BOOL)setup;

/*!
 * Start the audio angine, abstract
 *
 * @return YES on success, NO on failure
 */
- (BOOL)start;

/*!
 * Stop the audio engine, abstract
 */
- (void)stop;

/*!
 * set audio engine input format, abstract
 */
- (BOOL)setInputAudioFormat:(AudioStreamBasicDescription)asbd;

/*!
 * set audio engine output format, abstract
 */
- (BOOL)setOutputAudioFormat:(AudioStreamBasicDescription)asbd;

/*!
 * engine's delegate, provide audio flow callback
 */
- (void) setDelegate:(nullable id<AudioControllerDelegate>)delegate;

@end


@protocol AudioControllerDelegate <NSObject>

/*!
 * callback function, when engine running, engine pull play data from you
 */
- (NSData* _Nonnull)audioEnginePlayCallback:(NSInteger)length;

/*!
 * callback function, when engine running, engine push record data to you
 */
- (void)audioEngineRecordCallback:(NSData* _Nonnull)audioBuffer;

@end

//static BOOL _ASCheckOSStatus(OSStatus result, const char * _Nonnull operation, const char * _Nonnull file, int line);
