//
//  AppDelegate.h
//  AIMediaPlayer
//
//  Created by terence on 2019/6/29.
//  Copyright © 2019年 terence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

