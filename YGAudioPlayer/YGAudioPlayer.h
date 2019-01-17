//
//  YGAudioPlayer.h
//  YGAudioPlayer
//
//  Created by hou hui on 2019/1/17.
//  Copyright © 2019 dailyyoga. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^YGAudioPlayerUpdateProgressBlock)(CGFloat prorgress, CGFloat currTime, CGFloat totalDuration);
typedef void(^YGAudioPlayerStartPlayBlock)(void);
typedef void(^YGAudioPlayerEndPlayBlock)(void);
typedef void(^YGAudioPlayerUpdateBufferProgressBlock)(NSTimeInterval totalBuffer);
typedef void(^YGAudioPlayerChangeNewPlayItemBlock)(AVPlayer *player);
typedef void(^YGAudioPlayerChangePlayRateBlock)(CGFloat playRate);

@interface YGAudioPlayer : NSObject

+ (instancetype)sharedInstance;

- (void)audioPlayerWithURL:(NSURL *)playerItemURL;

- (void)pause;

- (void)resume;

- (void)seekToProgress:(CGFloat)progress;


@property (nonatomic, copy) YGAudioPlayerStartPlayBlock startPlayBlock;
@property (nonatomic, copy) YGAudioPlayerEndPlayBlock endPlayBlock;
@property (nonatomic, copy) YGAudioPlayerUpdateProgressBlock updateProgressBlock;
@property (nonatomic, copy) YGAudioPlayerUpdateBufferProgressBlock bufferProgressBlock;
@property (nonatomic, copy) YGAudioPlayerChangeNewPlayItemBlock changePlayItemBlock;
@property (nonatomic, copy) YGAudioPlayerChangePlayRateBlock playRateBlock;



@end

NS_ASSUME_NONNULL_END
