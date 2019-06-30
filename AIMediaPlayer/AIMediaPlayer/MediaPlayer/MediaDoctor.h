//
//  MediaDoctor.h
//  AIMediaPlayer
//
//  Created by terence on 2019/6/29.
//  Copyright © 2019年 terence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ResultBlock)(int count);

@interface MediaDoctor : NSObject

- (instancetype)initWithMediaURL:(NSString *)urlStr;
- (void)predictionWithImage:(UIImage *)image count:(int)count;
-(void)checkMedia;
    
@property(nonatomic,copy)ResultBlock resultBlock;
    @property(nonatomic,assign)int mediaSecond;//媒体总时长
    @property(nonatomic,strong)NSMutableArray *resultArray;
@end

NS_ASSUME_NONNULL_END
