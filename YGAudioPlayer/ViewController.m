//
//  ViewController.m
//  YGAudioPlayer
//
//  Created by hou hui on 2019/1/17.
//  Copyright © 2019 dailyyoga. All rights reserved.
//

#import "ViewController.h"
#import "YGAudioPlayer.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISlider *progressSider;
@property (weak, nonatomic) IBOutlet UILabel *currPlayTIme;
@property (weak, nonatomic) IBOutlet UILabel *totalTime;
@property (weak, nonatomic) IBOutlet UIProgressView *loadingProgressVie;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)playLocalAudio:(id)sender {
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"intro" ofType:@"mp3"]];
    YGAudioPlayer *player = [YGAudioPlayer sharedInstance];
    player.playStatusChangeBlock = ^(YGAudioPlayerPlayStatus status) {
        switch (status) {
            case YGAudioPlayerPlayStatusNone: {
                NSLog(@"未播放");
            }break;
            case YGAudioPlayerPlayStatusStart: {
                NSLog(@"开始播放");
            }break;
            case YGAudioPlayerPlayStatusPlaying: {
                NSLog(@"正在播放");
            }break;
            case YGAudioPlayerPlayStatusPause: {
                NSLog(@"停止播放");
            }break;
            case YGAudioPlayerPlayStatusCompleted: {
                NSLog(@"完成播放");
            }break;
            case YGAudioPlayerPlayStatusError: {
                NSLog(@"播放错误");
            }break;
                
            default:
                break;
        }
    };
    player.updateProgressBlock = ^(CGFloat prorgress, CGFloat currTime, CGFloat totalDuration) {
        self.progressSider.value = prorgress;
        NSInteger intCurrTime = currTime;
        NSInteger intTotalTime = totalDuration;
        self.currPlayTIme.text = [NSString stringWithFormat:@"%2d:%2d",intCurrTime/60,intCurrTime%60];
        self.totalTime.text = [NSString stringWithFormat:@"%2d:%2d",intTotalTime/60,intTotalTime%60];
    };
    [player audioPlayerWithURL:url];
}

- (IBAction)playStreamAudio:(id)sender {
    
    NSURL *url = [NSURL URLWithString:@"http://s3.amazonaws.com/dailyyoga/2/datapkg/en_Meditation+Courses/Elisha+Beginner/Relax+and+Retune+10+minutes.mp3"];
//    http://s3.amazonaws.com/dailyyoga/2/datapkg/en_Meditation+Courses/Elisha+Beginner/Relax+and+Retune+10+minutes.mp3
//    https://s3.amazonaws.com/dailyyoga/2/datapkg/en_Meditation+Courses/Elisha+Beginner/intro/intro.mp3
    YGAudioPlayer *player = [YGAudioPlayer sharedInstance];
    [player audioPlayerWithURL:url];
    player.playStatusChangeBlock = ^(YGAudioPlayerPlayStatus status) {
        switch (status) {
            case YGAudioPlayerPlayStatusNone: {
                NSLog(@"未播放");
            }break;
            case YGAudioPlayerPlayStatusStart: {
                NSLog(@"开始播放");
            }break;
            case YGAudioPlayerPlayStatusPlaying: {
                NSLog(@"正在播放");
            }break;
            case YGAudioPlayerPlayStatusPause: {
                NSLog(@"停止播放");
            }break;
            case YGAudioPlayerPlayStatusCompleted: {
                NSLog(@"完成播放");
            }break;
            case YGAudioPlayerPlayStatusError: {
                NSLog(@"播放错误");
            }break;
                
            default:
                break;
        }
    };
    player.updateProgressBlock = ^(CGFloat prorgress, CGFloat currTime, CGFloat totalDuration) {
        self.progressSider.value = prorgress;
        NSInteger intCurrTime = currTime;
        NSInteger intTotalTime = totalDuration;
        self.currPlayTIme.text = [NSString stringWithFormat:@"%2d:%2d",intCurrTime/60,intCurrTime%60];
        self.totalTime.text = [NSString stringWithFormat:@"%2d:%2d",intTotalTime/60,intTotalTime%60];
    };
}

- (IBAction)progressValueChange:(UISlider *)sender {
    
    [[YGAudioPlayer sharedInstance] seekToProgress:sender.value];
    
}
- (IBAction)pauseAction:(id)sender {
    
    YGAudioPlayer *player = [YGAudioPlayer sharedInstance];
    [player pause];
}

- (IBAction)playAction:(id)sender {
    YGAudioPlayer *player = [YGAudioPlayer sharedInstance];
    [player play];
}

@end
