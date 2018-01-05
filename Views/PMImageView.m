//
//  PMImageView.m
//  FranceTV
//
//  Created by Guillaume Salva on 1/5/16.
//  Copyright © 2016 Guillaume Salva. All rights reserved.
//

#import "PMImageView.h"

#import "PMOperationQueue.h"

#import "NSString+PMCrypt.h"
#import "NSString+PMRandom.h"

@interface PMImageViewManager : NSObject

@property (nonatomic, strong) NSString *cache_path;
@property (nonatomic, assign) NSTimeInterval file_cache_time;
@property (nonatomic, assign) NSTimeInterval memory_cache_time;
@property (nonatomic, assign) NSTimeInterval request_timeout;

@property (nonatomic, strong) PMOperationQueue *queue_manager;

@property (nonatomic, strong) NSMutableDictionary *dico_memory_cache;
@property (nonatomic, strong) NSMutableDictionary *dico_memory_cache_time;

@property (nonatomic, strong) NSURLSession *load_network_manager;
@property (nonatomic, strong) NSMutableDictionary *dico_load_network_manager;

+ (nonnull PMImageViewManager *)sharedManager;

- (NSString *)addBlockOperation:(NSBlockOperation *)blockOperation;
- (void)cancelBlockOperation:(NSString *)blockOperationID;

+ (NSString *)fileCachePath:(NSURL *)url withName:(NSString *)name;

- (UIImage *)imageFromMemory:(NSString *)hash;
- (UIImage *)imageFromFile:(NSString *)file_path;

- (NSString *)loadImageFromNetwork:(NSURL *)url
                    withCompletion:(void (^)(UIImage *network_image))completion;
- (void)cancelLoadImageFromNetwork:(NSString *)load_key;

+ (CGRect)sourceRectForImageSize:(CGSize)imageSize
                  andDisplaySize:(CGSize)displaySize
                  andContentMode:(UIViewContentMode)contentMode;
+ (CGRect)destinationRectForImageSize:(CGSize)imageSize
                          displaySize:(CGSize)displaySize
                          contentMode:(UIViewContentMode)contentMode;
+ (UIImage *)transformImage:(UIImage *)imgSource
               forImageSize:(CGSize)imageSize
            andImageContent:(UIViewContentMode)imageContentMode;

@end



@interface PMImageView ()

@property (nonatomic, strong) NSString *block_operation_uuid;
@property (nonatomic, strong) NSString *load_image_network_key;

@end


@implementation PMImageView

#pragma mark - Instance methods

+ (void)cachePath:(NSString *_Nullable)cache_path
{
    [[PMImageViewManager sharedManager] setCache_path:cache_path];
}

+ (void)fileCacheTime:(NSTimeInterval)file_cache_time
{
    [[PMImageViewManager sharedManager] setFile_cache_time:file_cache_time];
}

+ (void)memoryCacheTime:(NSTimeInterval)memory_cache_time
{
    [[PMImageViewManager sharedManager] setMemory_cache_time:memory_cache_time];
}

+ (void)requestTimeout:(NSTimeInterval)request_timeout
{
    [[PMImageViewManager sharedManager] setRequest_timeout:request_timeout];
}

+ (void)clearCache
{
}


#pragma mark - Public methods

- (void)setUrl:(NSURL *)url
{
    if((nil == _url) &&
       (nil == url) &&
       ![[_url absoluteString] isEqualToString:[url absoluteString]]) {
        [self cancel];
    }
    _url = url;
}

- (void)load:(nullable void (^)(NSError *_Nullable error))completion
{
    if(nil != _placeholder_view) {
        _placeholder_view.hidden = NO;
        _placeholder_view.alpha = 1.0;
        [self bringSubviewToFront:_placeholder_view];
    }
    
    if(nil == self.url) {
        [self _sendCompletion:completion withError:[NSError errorWithDomain:@"PMImageView"
                                                  code:-10
                                              userInfo:@{
                                                         NSLocalizedFailureReasonErrorKey: @"URL not set"
                                                         }]];
    }
    else {
        __weak typeof(self) weakSelf = self;
        
        NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakBlockOperation = blockOperation;
        [blockOperation addExecutionBlock:^{
            if([weakBlockOperation isCancelled]) {
                return ;
            }
            NSString *name = [weakSelf _hash];
            
            // Try load from memory
            UIImage *img = [[PMImageViewManager sharedManager] imageFromMemory:name];
            if((nil != img) && ![weakBlockOperation isCancelled]) {
                [weakSelf _setImage:img
                     withCompletion:nil];
            }
            else if(![weakBlockOperation isCancelled]) {
                // Try load from file
                img = [[PMImageViewManager sharedManager] imageFromFile:[PMImageViewManager fileCachePath:weakSelf.url withName:name]];
                if((nil != img) && ![weakBlockOperation isCancelled]) {
                    [weakSelf _setImage:img
                         withCompletion:completion];
                }
                else if(![weakBlockOperation isCancelled]) {
                    // Try by loading original to transform
                    UIImage *img_original = [[PMImageViewManager sharedManager] imageFromFile:[PMImageViewManager fileCachePath:weakSelf.url withName:nil]];
                    if((nil != img_original) && ![weakBlockOperation isCancelled]) {
                        // Has original
                        [weakSelf _handleOriginal:img_original
                                andOperationBlock:weakBlockOperation
                                    withFinalName:name
                                  andSaveOriginal:NO
                                    andCompletion:completion];
                    }
                    else if(![weakBlockOperation isCancelled]) {
                        // Need to get original
                        if([self.url isFileURL]) {
                            NSError *err_file = nil;
                            if([[NSFileManager defaultManager] fileExistsAtPath:[weakSelf.url path]]) {
                                [[NSFileManager defaultManager] copyItemAtPath:[weakSelf.url path]
                                                                        toPath:[PMImageViewManager fileCachePath:weakSelf.url withName:nil]
                                                                         error:&err_file];
                                if((nil == err_file) && ![weakBlockOperation isCancelled]) {
                                    [weakSelf _handleOriginal:[[PMImageViewManager sharedManager] imageFromFile:[PMImageViewManager fileCachePath:weakSelf.url withName:nil]]
                                            andOperationBlock:weakBlockOperation
                                                withFinalName:name
                                              andSaveOriginal:YES
                                                andCompletion:completion];
                                }
                            }
                            else {
                                err_file = [NSError errorWithDomain:@"PMImageView"
                                                               code:-11
                                                           userInfo:@{
                                                                      NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"File at path: %@ not found", self.url]
                                                                      }];
                            }
                            
                            if((nil != err_file) && ![weakBlockOperation isCancelled]) {
                                [weakSelf _sendCompletion:completion withError:err_file];
                            }
                        }
                        else {
                            weakSelf.load_image_network_key = [[PMImageViewManager sharedManager] loadImageFromNetwork:weakSelf.url
                                                                                                        withCompletion:^(UIImage *network_image) {
                                                                                                            if(![weakBlockOperation isCancelled]) {
                                                                                                                if(nil != network_image) {
                                                                                                                    [weakSelf _handleOriginal:network_image
                                                                                                                            andOperationBlock:weakBlockOperation
                                                                                                                                withFinalName:name
                                                                                                                              andSaveOriginal:YES
                                                                                                                                andCompletion:completion];
                                                                                                                }
                                                                                                                else {
                                                                                                                    [weakSelf _sendCompletion:completion withError:[NSError errorWithDomain:@"PMImageView"
                                                                                                                                                                                       code:-14
                                                                                                                                                                                   userInfo:@{
                                                                                                                                                                                              NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Can't load from network: %@", self.url]
                                                                                                                                                                                              }]];
                                                                                                                }
                                                                                                            }
                                                                                                        }];
                        }
                    }
                }
            }
        }];
        self.load_image_network_key = nil;
        self.block_operation_uuid = [[PMImageViewManager sharedManager] addBlockOperation:blockOperation];
    }
}

- (void)cancel
{
    [[PMImageViewManager sharedManager] cancelBlockOperation:self.block_operation_uuid];
    self.block_operation_uuid = nil;
    
    [[PMImageViewManager sharedManager] cancelLoadImageFromNetwork:self.load_image_network_key];
    self.load_image_network_key = nil;
}


#pragma mark - Private methods

- (NSString *)_hash
{
    return [[NSString stringWithFormat:@"%@-%@-%ld",
             [self.url absoluteString],
             NSStringFromCGSize(self.frame.size),
             self.contentMode] md5];
}

- (void)_sendCompletion:(nullable void (^)(NSError *_Nullable error))completion
              withError:(NSError *)err
{
    if(nil == completion) {
        return;
    }

    if(![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _sendCompletion:completion
                        withError:err];
        });
        return;
    }
    
    completion(err);
}

- (void)_setImage:(UIImage *)img
   withCompletion:(nullable void (^)(NSError *_Nullable error))completion
{
    if(![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
           [self _setImage:img
            withCompletion:completion];
        });
        return;
    }
    
    switch (_animation_style) {
        case PMImageViewAnimationStyleFade:
        {
            CGFloat old_alpha = self.alpha;
            self.alpha = 0.0;
            [self setImage:img];
            [UIView animateWithDuration:0.3
                                  delay:0.0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.alpha = old_alpha;
                                 if(nil != _placeholder_view) {
                                     _placeholder_view.alpha = 0.0;
                                 }
                             }
                             completion:^(BOOL finished) {
                                 if(finished) {
                                     if(nil != _placeholder_view) {
                                         _placeholder_view.hidden = YES;
                                     }
                                     if(nil != completion) {
                                         completion(nil);
                                     }
                                 }
                             }];
        }
            break;
        default:
        {
            [self setImage:img];
            if(nil != _placeholder_view) {
                _placeholder_view.hidden = YES;
            }
            if(nil != completion) {
                completion(nil);
            }
        }
            break;
    }
}

- (void)_saveImageToDisk:(UIImage *)img
                withName:(NSString *)name
{
    if(nil != img) {
        NSString *path_transformed_image = [PMImageViewManager fileCachePath:self.url withName:name];
        [UIImagePNGRepresentation(img) writeToFile:path_transformed_image atomically:YES];
    }
}

#warning TODO: caching memory + cleanup

- (void)_handleOriginal:(UIImage *)img_original
      andOperationBlock:(NSBlockOperation *)operation_block
          withFinalName:(NSString *)name
        andSaveOriginal:(BOOL)save_original
          andCompletion:(nullable void (^)(NSError *_Nullable error))completion
{
    if((nil != operation_block) && [operation_block isCancelled]) {
        return;
    }
    
    if(nil == img_original) {
        [self _sendCompletion:completion
                    withError:[NSError errorWithDomain:@"PMImageView"
                                                  code:-12
                                              userInfo:@{
                                                         NSLocalizedFailureReasonErrorKey: @"Original file not accessible"
                                                         }]];
    }
    else {
        if(save_original) {
            [self _saveImageToDisk:img_original
                          withName:nil];
        }
        
        UIImage *final_img = nil;
        if(nil == _transformationBlock) {
            final_img = [PMImageViewManager transformImage:img_original
                                              forImageSize:self.frame.size
                                           andImageContent:self.contentMode];
        }
        else {
            final_img = self.transformationBlock(img_original);
        }
        
        if((nil == operation_block) || ![operation_block isCancelled]) {
            if(nil != final_img) {
                [self _saveImageToDisk:final_img withName:name];
                [self _setImage:final_img
                 withCompletion:completion];
            }
            else {
                [self _sendCompletion:completion
                            withError:[NSError errorWithDomain:@"PMImageView"
                                          code:-13
                                      userInfo:@{
                                                 NSLocalizedFailureReasonErrorKey: @"Can't generate final image"
                                                 }]];
            }
        }
    }
}

@end


@implementation PMImageViewManager

+ (nonnull PMImageViewManager *)sharedManager
{
    static PMImageViewManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    self = [super init];
    
    self.cache_path = nil;
    
    self.request_timeout = 0.0;
    self.file_cache_time = 0.0;
    self.memory_cache_time = 0.0;
    
    self.queue_manager = [[PMOperationQueue alloc] init];
    [self.queue_manager setMaxConcurrentOperationCount:10];
    
    self.dico_memory_cache = [[NSMutableDictionary alloc] init];
    self.dico_memory_cache_time = [[NSMutableDictionary alloc] init];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    //[configuration setTimeoutIntervalForRequest:10.0];
    //[configuration setTimeoutIntervalForResource:60.0];
    self.load_network_manager = [NSURLSession sessionWithConfiguration:configuration];
    self.dico_load_network_manager = [[NSMutableDictionary alloc] init];
    
    return self;
}


#pragma mark - Setter

- (void)setCache_path:(NSString *)cache_path
{
    if(nil == cache_path) {
        cache_path = NSTemporaryDirectory();
    }
    else {
        if(![[NSFileManager defaultManager] fileExistsAtPath:cache_path]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:cache_path
                                      withIntermediateDirectories:NO
                                                       attributes:nil
                                                            error:nil];
        }
    }
    
    _cache_path = [cache_path stringByAppendingPathComponent:@"pm_image_view"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:_cache_path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:_cache_path
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil];
    }
}

- (void)setRequest_timeout:(NSTimeInterval)request_timeout
{
    if(request_timeout <= 0.0) {
        _request_timeout = 20.0; // 20 sec
    }
    else {
        _request_timeout = request_timeout;
    }
}

- (void)setFile_cache_time:(NSTimeInterval)file_cache_time
{
    if(_file_cache_time <= 0.0) {
        _file_cache_time = 60.0 * 60.0 * 24.0 * 30.0; // 30 days
    }
    else {
        _file_cache_time = file_cache_time;
    }
}

- (void)setMemory_cache_time:(NSTimeInterval)memory_cache_time
{
    if(memory_cache_time <= 0.0) {
        _memory_cache_time = 60.0; // 60 sec
    }
    else {
        _memory_cache_time = memory_cache_time;
    }
}


#pragma mark - Methods

- (NSString *)addBlockOperation:(NSBlockOperation *)blockOperation;
{
    return [self.queue_manager queueOperation:blockOperation];
}

- (void)cancelBlockOperation:(NSString *)blockOperationID
{
    [self.queue_manager cancelOperation:blockOperationID];
}

+ (NSString *)fileCachePath:(NSURL *)url withName:(NSString *)name
{
    NSString *result = nil;
    
    if(nil != url) {
        result = [[[PMImageViewManager sharedManager] cache_path] stringByAppendingPathComponent:[[url absoluteString] md5]];
        if(![[NSFileManager defaultManager] fileExistsAtPath:result]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:result
                                      withIntermediateDirectories:NO
                                                       attributes:nil
                                                            error:nil];
        }
        
        result = [result stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",
                                                         (nil == name) ? @"original" : name,
                                                         [url pathExtension]]];
    }
    
    return result;
}

- (UIImage *)imageFromMemory:(NSString *)hash
{
    UIImage *result = nil;

    if(nil != hash) {
        result = [self.dico_memory_cache objectForKey:hash];
        
        NSDate *stored_date = [self.dico_memory_cache_time objectForKey:hash];
        if((nil == stored_date) ||
           (fabs([stored_date timeIntervalSinceNow]) > self.memory_cache_time)) {
            result = nil;

            // Cleanup
            [self.dico_memory_cache removeObjectForKey:hash];
            [self.dico_memory_cache_time removeObjectForKey:hash];
        }
    }
    
    return result;
}

- (UIImage *)imageFromFile:(NSString *)file_path
{
    UIImage *result = nil;
    
    if(nil != file_path) {
        result = [UIImage imageWithContentsOfFile:file_path];
    }
    
    return result;
}

- (NSString *)loadImageFromNetwork:(NSURL *)url
                    withCompletion:(void (^)(UIImage *network_image))completion
{
    NSString *load_key = nil;
    if(nil != url) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        load_key = [NSString randomKey];
        
        __weak typeof(self) weakSelf = self;
        NSURLSessionTask *image_task = [self.load_network_manager dataTaskWithRequest:request
                                                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                                        UIImage *image_network = nil;
                                                                        if((nil != data) && (nil == error)) {
                                                                            image_network = [UIImage imageWithData:data];
                                                                        }
                                                                        
                                                                        [weakSelf.dico_load_network_manager removeObjectForKey:load_key];
                                                                        
                                                                        if(completion) {
                                                                            completion(image_network);
                                                                        }
                                                                    } ];
        [self.dico_load_network_manager setObject:image_task forKey:load_key];
        [image_task resume];
    }
    else if (nil != completion) {
        completion(nil);
    }
    return load_key;
}

- (void)cancelLoadImageFromNetwork:(NSString *)load_key
{
    if(nil != load_key) {
        NSURLSessionDownloadTask *image_task = [self.dico_load_network_manager objectForKey:load_key];
        if(nil != image_task) {
            [image_task cancel];
        }
    }
}


#pragma mark - Transformation image

+ (CGRect)sourceRectForImageSize:(CGSize)imageSize
                  andDisplaySize:(CGSize)displaySize
                  andContentMode:(UIViewContentMode)contentMode
{
    if((UIViewContentModeScaleToFill == contentMode) ||
       (UIViewContentModeScaleAspectFit == contentMode)) {
        return CGRectMake(0.0,
                          0.0,
                          imageSize.width,
                          imageSize.height);
    }
    else if(UIViewContentModeScaleAspectFill == contentMode) {
        CGFloat scale = MIN(imageSize.width / displaySize.width,
                            imageSize.height / displaySize.height);
        CGSize scaledDisplaySize = CGSizeMake(displaySize.width * scale, displaySize.height * scale);
        return CGRectMake(floorf((imageSize.width - scaledDisplaySize.width) / 2.0),
                          floorf((imageSize.height - scaledDisplaySize.height) / 2.0),
                          scaledDisplaySize.width,
                          scaledDisplaySize.height);
    }
    else if(UIViewContentModeCenter == contentMode) {
        return CGRectMake(floorf((imageSize.width - displaySize.width) / 2.0),
                          floorf((imageSize.width - displaySize.width) / 2.0),
                          displaySize.width,
                          displaySize.height);
    }
    else if(UIViewContentModeTop == contentMode) {
        return CGRectMake(floorf((imageSize.width - displaySize.width) / 2.0),
                          0.0,
                          displaySize.width, displaySize.height);
    }
    else if(UIViewContentModeBottom == contentMode) {
        return CGRectMake(floorf((imageSize.width - displaySize.width) / 2.0),
                          imageSize.height - displaySize.height,
                          displaySize.width, displaySize.height);
    }
    else if(UIViewContentModeLeft == contentMode) {
        return CGRectMake(0.0,
                          floorf((imageSize.width - displaySize.width) / 2.0),
                          displaySize.width,
                          displaySize.height);
    }
    else if(UIViewContentModeRight == contentMode) {
        return CGRectMake(imageSize.width - displaySize.width,
                          floorf((imageSize.width - displaySize.width) / 2.0),
                          displaySize.width,
                          displaySize.height);
    }
    else if(UIViewContentModeTopLeft == contentMode) {
        return CGRectMake(0.0,
                          0.0,
                          displaySize.width,
                          displaySize.height);
    }
    else if(UIViewContentModeTopRight == contentMode) {
        return CGRectMake(imageSize.width - displaySize.width,
                          0.0,
                          displaySize.width,
                          displaySize.height);
    }
    else if(UIViewContentModeBottomLeft == contentMode) {
        return CGRectMake(0.0,
                          imageSize.height - displaySize.height,
                          displaySize.width,
                          displaySize.height);
    }
    else if(UIViewContentModeBottomRight == contentMode) {
        return CGRectMake(imageSize.width - displaySize.width,
                          imageSize.height - displaySize.height,
                          displaySize.width,
                          displaySize.height);
    }
    else{
        return CGRectMake(0.0,
                          0.0,
                          imageSize.width,
                          imageSize.height);
    }
}

+ (CGRect)destinationRectForImageSize:(CGSize)imageSize
                          displaySize:(CGSize)displaySize
                          contentMode:(UIViewContentMode)contentMode
{
    if(UIViewContentModeScaleAspectFit == contentMode) {
        CGFloat scale = MIN(displaySize.width / imageSize.width,
                            displaySize.height / imageSize.height);
        CGSize scaledImageSize = CGSizeMake(imageSize.width * scale, imageSize.height * scale);
        return CGRectMake(floorf((displaySize.width - scaledImageSize.width) / 2.0),
                          floorf((displaySize.height - scaledImageSize.height) / 2.0),
                          scaledImageSize.width,
                          scaledImageSize.height);
    }
    else if((UIViewContentModeScaleToFill == contentMode) ||
             (UIViewContentModeScaleAspectFill == contentMode) ||
             (UIViewContentModeCenter == contentMode) ||
             (UIViewContentModeTop == contentMode) ||
             (UIViewContentModeBottom == contentMode) ||
             (UIViewContentModeLeft == contentMode) ||
             (UIViewContentModeRight == contentMode) ||
             (UIViewContentModeTopLeft == contentMode) ||
             (UIViewContentModeTopRight == contentMode) ||
             (UIViewContentModeBottomLeft == contentMode) ||
             (UIViewContentModeBottomRight == contentMode)) {
        return CGRectMake(0.0,
                          0.0,
                          displaySize.width,
                          displaySize.height);
    }
    else {
        return CGRectMake(0.0,
                          0.0,
                          displaySize.width,
                          displaySize.height);
    }
}

+ (UIImage *)transformImage:(UIImage *)imgSource
               forImageSize:(CGSize)imageSize
            andImageContent:(UIViewContentMode)imageContentMode
{
    UIImage *result = nil;
    
    if(imgSource && (imgSource.size.width > 0.0) && (imgSource.size.height > 0.0)) {
        result = imgSource;
        
        CGImageRef srcImageRef = imgSource.CGImage;
        CGImageRef croppedImageRef = nil;
        CGImageRef trimmedImageRef = nil;
        
        CGSize displaySize = imageSize;
        UIViewContentMode contentMode = imageContentMode;
        CGRect srcRect = CGRectMake(0.0, 0.0, imgSource.size.width, imgSource.size.height);
        
        if ((0.0 < displaySize.width) && (0.0 < displaySize.height)) {
            CGRect srcCropRect = [PMImageViewManager sourceRectForImageSize:srcRect.size
                                        andDisplaySize:displaySize
                                        andContentMode:imageContentMode];
            
            srcCropRect = CGRectMake(floorf(srcCropRect.origin.x),
                                     floorf(srcCropRect.origin.y),
                                     roundf(srcCropRect.size.width),
                                     roundf(srcCropRect.size.height));
            
            if (!CGRectEqualToRect(srcCropRect, srcRect)) {
                srcImageRef = CGImageCreateWithImageInRect(srcImageRef, srcCropRect);
                trimmedImageRef = srcImageRef;
                
                srcRect = CGRectMake(0,
                                     0,
                                     CGRectGetWidth(srcCropRect),
                                     CGRectGetHeight(srcCropRect));
                
                if (nil != croppedImageRef) {
                    CGImageRelease(croppedImageRef);
                    croppedImageRef = nil;
                }
            }
            
            CGRect dstBlitRect = [PMImageViewManager destinationRectForImageSize:srcRect.size
                                                                         displaySize:displaySize
                                                                         contentMode:contentMode];
            dstBlitRect = CGRectMake(floorf(dstBlitRect.origin.x),
                                     floorf(dstBlitRect.origin.y),
                                     roundf(dstBlitRect.size.width),
                                     roundf(dstBlitRect.size.height));
            
            displaySize = CGSizeMake(roundf(displaySize.width), roundf(displaySize.height));
            
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGBitmapInfo bmi = (CGBitmapInfo)kCGImageAlphaPremultipliedLast;
            CGFloat screenScale = [[UIScreen mainScreen] scale];
            
            CGContextRef dstBmp = CGBitmapContextCreate(NULL,
                                                        displaySize.width * screenScale,
                                                        displaySize.height * screenScale,
                                                        8,
                                                        0,
                                                        colorSpace,
                                                        bmi);
            
            if (nil != dstBmp) {
                CGRect dstRect = CGRectMake(0, 0,
                                            displaySize.width * screenScale,
                                            displaySize.height * screenScale);
                
                CGContextClearRect(dstBmp, dstRect);
                CGContextSetInterpolationQuality(dstBmp, kCGInterpolationDefault);
                
                CGRect scaledBlitRect = CGRectMake(dstBlitRect.origin.x * screenScale,
                                                   dstBlitRect.origin.y * screenScale,
                                                   dstBlitRect.size.width * screenScale,
                                                   dstBlitRect.size.height * screenScale);
                
                CGContextDrawImage(dstBmp, scaledBlitRect, srcImageRef);
                
                CGImageRef resultImageRef = CGBitmapContextCreateImage(dstBmp);
                
                if (nil != resultImageRef) {
                    if ([[UIImage class] respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
                        result = [UIImage imageWithCGImage:resultImageRef
                                                     scale:screenScale
                                               orientation:imgSource.imageOrientation];
                    }
                    else {
                        result = [UIImage imageWithCGImage:resultImageRef];
                    }
                    CGImageRelease(resultImageRef);
                }
                
                CGContextRelease(dstBmp);
            }
            
            CGColorSpaceRelease(colorSpace);
            
        }
        else if (nil != croppedImageRef) {
            result = [UIImage imageWithCGImage:srcImageRef];
        }
        
        if (nil != trimmedImageRef) {
            CGImageRelease(trimmedImageRef);
        }
        if (nil != croppedImageRef) {
            CGImageRelease(croppedImageRef);
        }
    }
    
    if(result && ((result.size.width <= 0) || (result.size.height <= 0))) {
        result = nil;
    }

    return result;
}


@end
