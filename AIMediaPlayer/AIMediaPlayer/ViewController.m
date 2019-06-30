//
//  ViewController.m
//  AIMediaPlayer
//
//  Created by terence on 2019/6/29.
//  Copyright © 2019年 terence. All rights reserved.
//

#import "ViewController.h"
#import "MediaDoctor.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#define WeakSelf __weak typeof(self) weakSelf = self;

@interface ViewController ()
    @property(nonatomic,strong)MediaDoctor *doctor;
- (IBAction)playFunc:(id)sender;
    @property (weak, nonatomic) IBOutlet UISlider *progressSlider;
    @property (weak, nonatomic) IBOutlet UIView *viewDoctor;
    @property (nonatomic, strong) AVPlayer *player;
    @property (nonatomic, assign) BOOL isChangeValue;//正在拖拽
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *movpath =[[NSBundle mainBundle] pathForResource:@"nsfw" ofType:@"3gp"];
    if (!movpath) {
        return;
    }
    self.doctor = [[MediaDoctor alloc]initWithMediaURL:movpath];
    WeakSelf
    self.doctor.resultBlock = ^(int count) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [weakSelf updateDoctorViewAtStep:count];
            
        }];
        
    };
    
    
    [self.doctor checkMedia];
    [self playMediaOfUrl:movpath];
  
}


//更新viewDoctor 黄色为疑似NSFW，红色为严重少儿不宜
-(void)updateDoctorViewAtStep:(int)step{
    int length = self.viewDoctor.bounds.size.width;
    int height = self.viewDoctor.bounds.size.height;
    int sum = (int)self.doctor.resultArray.count;
    
    int subViewWidth = length/sum+1;
    int x = step*length/sum;
    
    UIColor *color = [UIColor greenColor];
    float confidence = [[self.doctor.resultArray objectAtIndex:step]floatValue];
    if (confidence>0.7) {
        color = [UIColor redColor];
    }
    else if(confidence>0.2){
        color = [UIColor yellowColor];
    }
    else{
        return;
    }
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(x, 0, subViewWidth, height)];
    view.backgroundColor=color;
    [self.viewDoctor addSubview:view];
    
    
    
}
    
    
    
-(void)playMediaOfUrl:(NSString *)urlStr{
    //为即将播放的视频内容进行建模
    AVPlayerItem *avplayerItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:urlStr]];
    //创建监听（这是一种KOV的监听模式）
    [avplayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //给播放器赋值要播放的对象模型
    self.player = [AVPlayer playerWithPlayerItem:avplayerItem];
    //指定显示的Layer
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    layer.frame = CGRectMake(0, 100, self.view.frame.size.width, 200);
    [self.view.layer addSublayer:layer];
    
    [self addProgressObserver];
    [self addObserverToPlayerItem:self.player.currentItem];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    [self.progressSlider addGestureRecognizer:tap];
    //[avplayer play];
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        //NSLog(@"%@",time);
        /// 更新播放进度
        //[weakSelf updateProgress];
    }];
   
}
    
    


    
    
#pragma mark - 监听
- (void)addProgressObserver {
    __weak typeof(self) weakSelf = self;
    
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (weakSelf.isChangeValue) {
            return;
        }
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([weakSelf.player.currentItem duration]);
        if (current) {
            [weakSelf.progressSlider setValue:(current / total) animated:YES];
        }
    }];
}
    
- (void)addObserverToPlayerItem:(AVPlayerItem *)playerItem {
    
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}
    
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        NSLog(@"状态%ld", status);
        if (status == AVPlayerStatusReadyToPlay) {
        }
    } else {
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;;
        NSLog(@"缓存总时长：%0.2f", totalBuffer);
    }
}
    
#pragma mark - 拖拽进度
    
- (IBAction)sliderChangeClick:(UISlider *)sender {
    
    //拖拽的时候先暂停
    BOOL isPlaying = false;
    if (self.player.rate > 0) {
        isPlaying = true;
        [self.player pause];
    }
    // 先不跟新进度
    self.isChangeValue = true;
    
    float fps = [[[self.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] nominalFrameRate];
    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(self.player.currentItem.duration) * sender.value, fps);
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        
        if (isPlaying) {
            [weakSelf.player play];
        }
        weakSelf.isChangeValue = false;
    }];
}
    
#pragma mark - 点击调进度
- (void)handleTap:(UITapGestureRecognizer *)sender {
    
    CGPoint touchPoint = [sender locationInView:self.progressSlider];
    CGFloat value = touchPoint.x / CGRectGetWidth(self.progressSlider.bounds);
    [self.progressSlider setValue:value animated:YES];
    [self sliderChangeClick:self.progressSlider];
}
    
    
    
    
    
- (IBAction)playFunc:(id)sender {
    if (self.player.rate == 0) {
        [sender setTitle:@"pause" forState:UIControlStateNormal];
        [self.player play];
    } else if (self.player.rate > 0) {
        [sender setTitle:@"start" forState:UIControlStateNormal];
        [self.player pause];
    }
}

-(void)dealloc {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

    
    
@end
