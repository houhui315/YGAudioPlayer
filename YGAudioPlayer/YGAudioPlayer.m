//
//  YGAudioPlayer.m
//  YGAudioPlayer
//
//  Created by hou hui on 2019/1/17.
//  Copyright © 2019 dailyyoga. All rights reserved.
//

#import "YGAudioPlayer.h"


@interface YGAudioPlayer ()

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) id timeObserver;

@property (nonatomic, assign) CGFloat waitPlayTime;

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

- (void)audioPlayerWithURL:(NSURL *)playerItemURL {
    
    [self currentItemRemoveOberver];
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:playerItemURL];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self currentItemAddObserver];
    
    self.playStatus = YGAudioPlayerPlayStatusNone;
    if (self.playStatusChangeBlock) {
        self.playStatusChangeBlock(self.playStatus);
    }
}

- (void)pause {
    
    [self.player pause];
    if (self.isPlaying) {
        self.isPlaying = NO;
        self.playStatus = YGAudioPlayerPlayStatusPause;
        if (self.playStatusChangeBlock) {
            self.playStatusChangeBlock(self.playStatus);
        }
    }
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
    if (!self.isPlaying) {
        self.isPlaying = YES;
        self.playStatus = YGAudioPlayerPlayStatusPlaying;
        if (self.playStatusChangeBlock) {
            self.playStatusChangeBlock(self.playStatus);
        }
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
    [self.player seekToTime:CMTimeMakeWithSeconds(second, self.player.currentItem.currentTime.timescale) completionHandler:^(BOOL finished) {
        if (finished) {
            
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
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    [self.player.currentItem addObserver:self forKeyPath:@"rate" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    
    //监控播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    
    //监控时间进度
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        // 在这里将监听到的播放进度代理出去，对进度条进行设置
        if (strongSelf.updateProgressBlock) {
            float totalDuration = CMTimeGetSeconds(strongSelf.player.currentItem.duration);
            float currtime = CMTimeGetSeconds(time);
            strongSelf.updateProgressBlock(currtime/totalDuration, currtime, totalDuration);
        }
    }];
}

- (void)currentItemRemoveOberver {
    
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"rate"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self.player removeTimeObserver:self.timeObserver];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[@"new"] integerValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay: {
                // 开始播放
                [self.player play];
                self.isPlaying = YES;
                // 代理回调，开始初始化状态
                self.playStatus = YGAudioPlayerPlayStatusStart;
                if (self.playStatusChangeBlock) {
                    self.playStatusChangeBlock(self.playStatus);
                }
            } break;
            case AVPlayerItemStatusFailed: {
                self.isPlaying = NO;
                self.playStatus = YGAudioPlayerPlayStatusError;
                if (self.playStatusChangeBlock) {
                    self.playStatusChangeBlock(self.playStatus);
                }
            } break;
            case AVPlayerItemStatusUnknown: {
                self.isPlaying = NO;
                self.playStatus = YGAudioPlayerPlayStatusError;
                if (self.playStatusChangeBlock) {
                    self.playStatusChangeBlock(self.playStatus);
                }
            } break;
            default:
                break;
        }
    }else if ([keyPath isEqualToString:@"rate"]) {
        // rate=1:播放，rate!=1:非播放
        float rate = self.player.rate;
        if (self.playRateBlock) {
            self.playRateBlock(rate);
        }
        NSLog(@"rate = %f",rate);
    }
}

- (void)playbackFinished:(NSNotification *)notifi {
    self.isPlaying = NO;
    self.playStatus = YGAudioPlayerPlayStatusCompleted;
    if (self.playStatusChangeBlock) {
        self.playStatusChangeBlock(self.playStatus);
    }
}

#pragma mark - lazy

- (AVPlayer *)player {
    
    if (!_player) {
        _player = [AVPlayer new];
        if (@available(iOS 10.0, *)) {
            _player.automaticallyWaitsToMinimizeStalling = NO;
            _player.currentItem.preferredForwardBufferDuration = 1;
        } else {
            // Fallback on earlier versions
        }
    }
    return _player;
}

@end
