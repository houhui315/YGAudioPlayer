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

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, assign) BOOL isLocalAudio;

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
    
    if ([playerItemURL.absoluteString hasPrefix:@"http"]) {
        self.isLocalAudio = NO;
        [self currentItemRemoveOberver];
        
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:playerItemURL];
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
        [self currentItemAddObserver];
    }else{
        self.isLocalAudio = YES;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:playerItemURL error:nil];
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer play];
    }
}

- (void)pause {
    
    if (self.isLocalAudio) {
        [self.audioPlayer pause];
    }else{
        [self.player pause];
    }
}

- (void)resume {
    
    if (self.isLocalAudio) {
        [self.audioPlayer playAtTime:self.audioPlayer.deviceCurrentTime];
    }else{
        [self.player play];
    }
}

- (void)seekToProgress:(CGFloat)progress {
    
    float totalDuration = CMTimeGetSeconds(self.player.currentItem.duration);
    CGFloat seekTime = totalDuration*progress;
    [self.player seekToTime:CMTimeMakeWithSeconds(seekTime, 1) completionHandler:^(BOOL finished) {
        if (finished) {
            [self.player play];
        }
    }];
}

- (void)currentItemAddObserver {
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    
    //监控缓冲加载情况属性
    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    
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
            NSLog(@"currtime = %.2f totlaTime = %.2f",currtime,totalDuration);
        }
    }];
}

- (void)currentItemRemoveOberver {
    
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self.player removeTimeObserver:self.timeObserver];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[@"new"] integerValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                // 开始播放
                [self.player play];
                // 代理回调，开始初始化状态
                if (self.startPlayBlock) {
                    self.startPlayBlock();
                }
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                NSLog(@"加载失败");
            }
                break;
            case AVPlayerItemStatusUnknown:
            {
                NSLog(@"未知资源");
            }
                break;
            default:
                break;
        }
    } else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = playerItem.loadedTimeRanges;
        //本次缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //缓冲总长度
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        NSLog(@"共缓冲：%.2f",totalBuffer);
        if (self.bufferProgressBlock) {
            self.bufferProgressBlock(totalBuffer);
        }
        
    } else if ([keyPath isEqualToString:@"rate"]) {
        // rate=1:播放，rate!=1:非播放
        float rate = self.player.rate;
        if (self.playRateBlock) {
            self.playRateBlock(rate);
        }
    } else if ([keyPath isEqualToString:@"currentItem"]) {
        NSLog(@"新的currentItem");
        if (self.changePlayItemBlock) {
            self.changePlayItemBlock(self.player);
        }
    }
}

- (void)playbackFinished:(NSNotification *)notifi {
    NSLog(@"播放完成");
    if (self.endPlayBlock) {
        self.endPlayBlock();
    }
}

#pragma mark - lazy

- (AVPlayer *)player {
    
    if (!_player) {
        _player = [AVPlayer new];
        if (@available(iOS 10.0, *)) {
            _player.automaticallyWaitsToMinimizeStalling = NO;
        } else {
            // Fallback on earlier versions
        }
        _player.volume = 0.5;
    }
    return _player;
}

@end
