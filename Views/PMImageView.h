//
//  PMImageView.h
//  FranceTV
//
//  Created by Guillaume Salva on 1/5/16.
//  Copyright © 2016 Guillaume Salva. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PMImageViewAnimationStyle) {
    PMImageViewAnimationStyleNone,
    PMImageViewAnimationStyleFade
};

@interface PMImageView : UIImageView

@property (nonatomic, strong) NSURL *_Nullable url;

@property (nonatomic, strong) UIView *_Nullable placeholder_view;
@property (nonatomic, assign) PMImageViewAnimationStyle animation_style;

@property (nonatomic, copy) UIImage *_Nullable (^_Nullable transformationBlock)(UIImage *_Nonnull original_image);


+ (void)cachePath:(NSString *_Nullable)cache_path;
+ (void)fileCacheTime:(NSTimeInterval)file_cache_time;
+ (void)memoryCacheTime:(NSTimeInterval)memory_cache_time;
+ (void)requestTimeout:(NSTimeInterval)request_timeout;
+ (void)clearCache;

- (void)load:(nullable void (^)(NSError *_Nullable error))completion;
- (void)cancel;

@end
