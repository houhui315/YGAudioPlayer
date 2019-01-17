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
    [player audioPlayerWithURL:url];
    player.startPlayBlock = ^{
        NSLog(@"startPlayBlock");
    };
    player.bufferProgressBlock = ^(NSTimeInterval totalBuffer) {
        self.loadingProgressVie.progress = totalBuffer/632;
        NSLog(@"bufferProgressBlock = %f",totalBuffer);
        
    };
    player.updateProgressBlock = ^(CGFloat prorgress, CGFloat currTime, CGFloat totalDuration) {
        NSLog(@"updateProgressBlock = %d",prorgress);
        self.progressSider.value = prorgress;
        NSInteger intCurrTime = currTime;
        NSInteger intTotalTime = totalDuration;
        self.currPlayTIme.text = [NSString stringWithFormat:@"%2d:%2d",intCurrTime/60,intCurrTime%60];
        self.totalTime.text = [NSString stringWithFormat:@"%2d:%2d",intTotalTime/60,intTotalTime%60];
    };
    player.changePlayItemBlock = ^(AVPlayer * _Nonnull player) {
        NSLog(@"startPlayBlock");
    };
}

- (IBAction)playStreamAudio:(id)sender {
    
    NSURL *url = [NSURL URLWithString:@"https://s3.amazonaws.com/dailyyoga/2/datapkg/en_Meditation+Courses/Elisha+Beginner/intro/intro.mp3"];
//    http://s3.amazonaws.com/dailyyoga/2/datapkg/en_Meditation+Courses/Elisha+Beginner/Relax+and+Retune+10+minutes.mp3
    
    YGAudioPlayer *player = [YGAudioPlayer sharedInstance];
    [player audioPlayerWithURL:url];
    player.startPlayBlock = ^{
        NSLog(@"startPlayBlock");
    };
    player.bufferProgressBlock = ^(NSTimeInterval totalBuffer) {
        self.loadingProgressVie.progress = totalBuffer/632;
        NSLog(@"bufferProgressBlock = %f",totalBuffer);
        
    };
    player.updateProgressBlock = ^(CGFloat prorgress, CGFloat currTime, CGFloat totalDuration) {
        NSLog(@"updateProgressBlock = %d",prorgress);
        self.progressSider.value = prorgress;
        NSInteger intCurrTime = currTime;
        NSInteger intTotalTime = totalDuration;
        self.currPlayTIme.text = [NSString stringWithFormat:@"%2d:%2d",intCurrTime/60,intCurrTime%60];
        self.totalTime.text = [NSString stringWithFormat:@"%2d:%2d",intTotalTime/60,intTotalTime%60];
    };
    player.changePlayItemBlock = ^(AVPlayer * _Nonnull player) {
        NSLog(@"startPlayBlock");
    };
}

- (IBAction)progressValueChange:(UISlider *)sender {
    
    YGAudioPlayer *player = [YGAudioPlayer sharedInstance];
    [player pause];
    [[YGAudioPlayer sharedInstance] seekToProgress:sender.value];
    
}
- (IBAction)pauseAction:(id)sender {
    
    YGAudioPlayer *player = [YGAudioPlayer sharedInstance];
    [player pause];
}

- (IBAction)playAction:(id)sender {
    YGAudioPlayer *player = [YGAudioPlayer sharedInstance];
    [player resume];
}

@end
