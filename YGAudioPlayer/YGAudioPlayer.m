//
//  YGAudioPlayer.m
//  YGAudioPlayer
//
//  Created by hou hui on 2019/1/17.
//  Copyright © 2019 dailyyoga. All rights reserved.
//

#import "YGAudioPlayer.h"


@interface YGAudioPlayer () {
    
}

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerItem *currentItem;

@property (nonatomic, strong) id timeObserver;

@property (nonatomic, assign) CGFloat waitPlayTime;

@property (nonatomic, assign) CMTime chaseTime;

@property (nonatomic, assign) BOOL isSeekInProgress;

@property (nonatomic, assign) CGFloat duration;

@end

@implementation YGAudioPlayer

static YGAudioPlayer* _instance = nil;

+ (instancetype)sharedInstance {
    
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    });
    return _instance ;
}

- (void)playAudioWithURL:(NSURL *)playerItemURL {
    
    [self currentItemRemoveOberver];
    if ([playerItemURL.absoluteString hasPrefix:@"http"]) {
        self.currentItem = [AVPlayerItem playerItemWithURL:playerItemURL];
    }else{
        AVAsset *asset = [AVAsset assetWithURL:playerItemURL];
        self.currentItem = [AVPlayerItem playerItemWithAsset:asset];
    }
    AVPlayer *player = [AVPlayer playerWithPlayerItem:self.currentItem];
    if (@available(iOS 10.0, *)) {
        player.automaticallyWaitsToMinimizeStalling = NO;
        player.currentItem.preferredForwardBufferDuration = 1;
    } else {
        // Fallback on earlier versions
    }
    self.player = player;
    [self currentItemAddObserver];
    [player play];
    self.playStatus = YGAudioPlayerPlayStatusStart;
    self.isPlaying = YES;
}

- (void)pause {
    
    [self.player pause];
    self.isPlaying = NO;
    self.playStatus = YGAudioPlayerPlayStatusPause;
}

- (void)stop {
    
    [self.player pause];
    self.isPlaying = NO;
    self.playStatus = YGAudioPlayerPlayStatusStop;
    [self currentItemRemoveOberver];
}

- (void)playAtTime:(CGFloat)time {
    
    self.waitPlayTime = time;
    [self play];
}

- (void)play {
    
    if (self.waitPlayTime > 0) {
        [self seekToSecond:self.waitPlayTime];
    }
    [self.player play];
    self.isPlaying = YES;
    self.playStatus = YGAudioPlayerPlayStatusPlaying;
}

- (void)setPlayStatus:(YGAudioPlayerPlayStatus)playStatus {
    
    _playStatus = playStatus;
    if (self.playStatusChangeBlock) {
        self.playStatusChangeBlock(self.playStatus);
    }
}

- (void)seekToProgress:(CGFloat)progress {
    
    float totalDuration = CMTimeGetSeconds(self.player.currentItem.duration);
    CGFloat seekTime = totalDuration * progress;
    self.waitPlayTime = seekTime;
    if (self.isPlaying && self.player && self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        [self seekToSecond:seekTime];
    }
}

- (void)seekToSecond:(CGFloat)second {
    
    self.waitPlayTime = 0;
    [self stopPlayingAndSeekSmoothlyToTime:CMTimeMakeWithSeconds(second, self.player.currentItem.currentTime.timescale)];
}

- (void)stopPlayingAndSeekSmoothlyToTime:(CMTime)newChaseTime {
    
    [self.player pause];
    if (CMTIME_COMPARE_INLINE(newChaseTime, !=, self.chaseTime)) {
        self.chaseTime = newChaseTime;
        if (!self.isSeekInProgress) {
            [self trySeekToChaseTime];
        }
    }
}

- (void)trySeekToChaseTime {
    
    if (self.player.currentItem.status == AVPlayerItemStatusUnknown) {
        
    }else if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay){
        [self actuallySeekToTime];
    }
}

- (void)actuallySeekToTime {
    
    self.isSeekInProgress = YES;
    CMTime seekTimeInProgress = self.chaseTime;
    BOOL isPlaying = self.isPlaying;
    @weakify(self);
    [self.player seekToTime:seekTimeInProgress toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        @strongify(self);
        if (CMTIME_COMPARE_INLINE(seekTimeInProgress, ==, self.chaseTime)) {
            self.isSeekInProgress = NO;
            if (isPlaying) {
                [self.player play];
            }
        }else{
            [self trySeekToChaseTime];
        }
    }];
}

- (NSUInteger)playTime {
    
    NSUInteger seconds = CMTimeGetSeconds(self.player.currentTime);
    return seconds;
}

- (NSUInteger)playDuration {
    
    NSUInteger seconds = CMTimeGetSeconds(self.player.currentItem.duration);
    return seconds;
}

- (void)currentItemAddObserver {
    
    self.duration = 0;
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [self.currentItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    //缓冲数据
    [self.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    // 缓冲区空了，需要等待数据
    [self.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options: NSKeyValueObservingOptionNew context:nil];
    // 缓冲区有足够数据可以播放了
    [self.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options: NSKeyValueObservingOptionNew context:nil];
    
    //监控播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentItem];
    
    //监控时间进度
    @weakify(self);
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        @strongify(self);
        // 在这里将监听到的播放进度代理出去，对进度条进行设置
        if (self.updateProgressBlock) {
            float totalDuration = self.duration;
            float currtime = CMTimeGetSeconds(time);
            CGFloat progress = 0;
            if (totalDuration > 0) {
                progress = currtime/totalDuration;
            }else{
                totalDuration = 0;
            }
            self.updateProgressBlock(progress, currtime, totalDuration);
        }
    }];
}

- (void)currentItemRemoveOberver {
    
    if (self.currentItem) {
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [self.player removeTimeObserver:self.timeObserver];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.currentItem = nil;
    }
    _player = nil;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[@"new"] integerValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay: {
                // 开始播放
                self.isPlaying = YES;
                self.duration = CMTimeGetSeconds(playerItem.duration);
                // 代理回调，开始初始化状态
                self.playStatus = YGAudioPlayerPlayStatusPlaying;
            } break;
            case AVPlayerItemStatusFailed: {
                self.isPlaying = NO;
                self.playStatus = YGAudioPlayerPlayStatusError;
                [self currentItemRemoveOberver];
            } break;
            case AVPlayerItemStatusUnknown: {
                self.isPlaying = NO;
                self.playStatus = YGAudioPlayerPlayStatusError;
                [self currentItemRemoveOberver];
            } break;
            default:
                break;
        }
        
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = playerItem.loadedTimeRanges;
        //本次缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //缓冲总长度
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        if (self.duration > 0) {
            self.bufferProgress = totalBuffer/self.duration;
        }else{
            self.bufferProgress = 0;
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        // 当缓冲是空的时候
        if (playerItem.playbackBufferEmpty) {
            self.playStatus = YGAudioPlayerPlayStatusBuffer;
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        // 当缓冲好的时候
        if (playerItem.playbackLikelyToKeepUp && self.playStatus == YGAudioPlayerPlayStatusBuffer) {
            self.playStatus = YGAudioPlayerPlayStatusPlaying;
        }
    }
}

- (void)playbackFinished:(NSNotification *)notifi {
    self.isPlaying = NO;
    self.playStatus = YGAudioPlayerPlayStatusCompleted;
    [self seekToProgress:0];
    if (self.updateProgressBlock) {
        self.updateProgressBlock(0, 0, self.playDuration);
    }
    [self currentItemRemoveOberver];
}


@end
