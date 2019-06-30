//
//  MediaDoctor.m
//  AIMediaPlayer
//
//  Created by terence on 2019/6/29.
//  Copyright © 2019年 terence. All rights reserved.
//

#import "MediaDoctor.h"
#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>
#import "NSFW.h"
#import <AVFoundation/AVFoundation.h>
#define WeakSelf __weak typeof(self) weakSelf = self;
#define totalStep 100


@interface MediaDoctor()
    @property(nonatomic,strong)AVAssetImageGenerator *assetImageGenerator;
    @property(nonatomic,strong)AVURLAsset *asset;

    @end


@implementation MediaDoctor
    
- (instancetype)initWithMediaURL:(NSString *)urlStr {
    
    MediaDoctor *_self=[super init];
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    _self.asset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    // 初始化视频媒体文件
    _self.mediaSecond = (int)_self.asset.duration.value / _self.asset.duration.timescale;
    // 获取视频总时长,单位秒
    
    
    NSParameterAssert(_self.asset);
    _self.assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:_self.asset];
    _self.assetImageGenerator.appliesPreferredTrackTransform = YES;
    _self.assetImageGenerator.apertureMode =AVAssetImageGeneratorApertureModeEncodedPixels;
    
    
    _self.resultArray=[[NSMutableArray alloc]initWithCapacity:totalStep];
    
    
    
    for (int i=0; i<totalStep; i++) {
        [_self.resultArray setObject:@"0" atIndexedSubscript:i];
    }
    
    return _self;
}
    
    
    
    
//改变图片的size
- (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size{
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}
    
    
    
- (void)predictionWithImage:(UIImage *)image count:(int)count{
    
    
    image = [self scaleToSize:image size:CGSizeMake(299, 299)];
    
    //两种初始化方法均可
    //    Resnet50* resnet50 = [[Resnet50 alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Resnet50" ofType:@"mlmodelc"]] error:nil];
    
    NSFW *model = [[NSFW alloc]init];
    NSError *error = nil;
    //创建VNCoreMLModel
    VNCoreMLModel *vnCoreMMModel = [VNCoreMLModel modelForMLModel:model.model error:&error];
    
    // 创建处理requestHandler
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];
    
    
    WeakSelf
    // 创建request
    VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:vnCoreMMModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        
        CGFloat confidence = 0.0f;
        

        
        VNClassificationObservation *classification=[request.results objectAtIndex:1];
        confidence = classification.confidence;//nsfw的概率
        [weakSelf.resultArray setObject:[NSString stringWithFormat:@"%f",confidence] atIndexedSubscript:count];
        
        if (confidence>0.3) {
            if (weakSelf.resultBlock) {
                weakSelf.resultBlock(count);
            }
            NSLog(@"%@",image.class);
        }

        NSLog(@"%@",[NSString stringWithFormat:@"nsfw匹配率:%.2f,step:%d",confidence,count]);
    }];
    
  
    
    // 发送识别请求
    [handler performRequests:@[request] error:&error];
    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
}
    
    
-(void)checkMedia{
    //琛哥说耗时的操作要异步
    NSOperationQueue *operationQueue=[[NSOperationQueue alloc]init];
    operationQueue.maxConcurrentOperationCount=5;//设置最大并发线程数
    [operationQueue addOperationWithBlock:^{
        for (int i = 0; i<totalStep; i++) {
            [self checkMediaByStep:i];
        }
    }];
}
    
    
    
    
-(void)checkMediaByStep:(int)step{
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = self.mediaSecond*step/totalStep;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [self.assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 1)actualTime:NULL error:&thumbnailImageGenerationError];
    //thumbnailImageRef = [self.assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60) actualTime:NULL error:&thumbnailImageGenerationError];
    
    
    if(!thumbnailImageRef){
        return;
        
    }
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage:thumbnailImageRef] : nil;
    

    [self predictionWithImage:thumbnailImage count:step];
}
    
@end
