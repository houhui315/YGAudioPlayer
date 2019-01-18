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

/*!
 播放状态枚举
 */
typedef NS_ENUM(NSUInteger, YGAudioPlayerPlayStatus) {
    
    ///未播放
    YGAudioPlayerPlayStatusNone,
    ///开始播放
    YGAudioPlayerPlayStatusStart,
    ///正在播放
    YGAudioPlayerPlayStatusPlaying,
    ///停止播放
    YGAudioPlayerPlayStatusPause,
    ///播放完成
    YGAudioPlayerPlayStatusCompleted,
    ///播放错误
    YGAudioPlayerPlayStatusError
};


typedef void(^YGAudioPlayerUpdateProgressBlock)(CGFloat prorgress, CGFloat currTime, CGFloat totalDuration);
typedef void(^YGAudioPlayerPlayStatysChangeBlock)(YGAudioPlayerPlayStatus status);
typedef void(^YGAudioPlayerChangePlayRateBlock)(CGFloat playRate);


@interface YGAudioPlayer : NSObject

+ (instancetype)sharedInstance;

/*!
 播放音频链接（包括网络URL和本地URL）
 */
- (void)audioPlayerWithURL:(NSURL *)playerItemURL;

/*!
 暂停播放
 */
- (void)pause;

/*!
 播放
 */
- (void)play;

/*!
 从什么时间开始播放
 */
- (void)playAtTime:(CGFloat)time;

/*!
 跳转到指定进度
 */
- (void)seekToProgress:(CGFloat)progress;

/*!
 当前播放时间（秒）
 */
- (NSUInteger)playTime;

/*!
 音频总时长（秒）
 */
- (NSUInteger)playDuration;

/*!
 是否正在播放
 */
@property (atomic, assign) BOOL isPlaying;

/*!
 当前播放状态
 */
@property (atomic, assign) YGAudioPlayerPlayStatus playStatus;

/*!
 更新播放进度回调，每秒调用一次
 */
@property (nonatomic, copy) YGAudioPlayerUpdateProgressBlock updateProgressBlock;

/*!
 播放状态改变回调
 */
@property (nonatomic, copy) YGAudioPlayerPlayStatysChangeBlock playStatusChangeBlock;
/*!
 */
@property (nonatomic, copy) YGAudioPlayerChangePlayRateBlock playRateBlock;



@end

NS_ASSUME_NONNULL_END
