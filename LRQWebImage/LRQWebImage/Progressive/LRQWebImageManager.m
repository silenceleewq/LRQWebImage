//
//  LRQWebImageManager.m
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/28.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

/**
    增加对operation的管理.
 */

#import "LRQWebImageManager.h"
#import "LRQWebImageOperation.h"

@interface  LRQImageCombinedOperation: NSObject <LRQWebImageOperation>
@property (assign, nonatomic, getter=isCancelled) BOOL cancelled;
@property (copy, nonatomic) LRQWebImageNoParamsBlock cancelBlock;
@property (strong, nonatomic) NSOperation *cacheOperation;
@end

@interface LRQWebImageManager ()

@property (strong, nonatomic) LRQImageCache *imageCache;
@property (strong, nonatomic) LRQWebImageDownloader *imageDownloader;
@property (strong, nonatomic) NSMutableSet *failedURLs;
@property (strong, nonatomic) NSMutableArray *runningOperations;

@end

@implementation LRQWebImageManager

+ (instancetype)sharedManager {
    static LRQWebImageManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    LRQImageCache *cache = [LRQImageCache sharedImageCache];
    LRQWebImageDownloader *downloader = [LRQWebImageDownloader sharedDonwloader];
    return [self initWithCache:cache downloader:downloader];
}

- (instancetype)initWithCache:(LRQImageCache *)cache downloader:(LRQWebImageDownloader *)downloader {
    self = [super init];
    if (self) {
        _imageCache = cache;
        _imageDownloader = downloader;
        _failedURLs = [NSMutableSet new];
        _runningOperations = [NSMutableArray array];
    }
    return self;
}

- (NSString *)cacheKeyForURL:(NSURL *)url
{
    if (!url) {
        return @"";
    }
    if (self.filterBlock) {
        return self.filterBlock(url);
    } else {
        return url.absoluteString;
    }
}

- (id <LRQWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(LRQWebImageOptions)options progress:(LRQWebImageDownloaderProgressBlock)progressBlock completed:(LRQWebImageCompletionWithFinishedBlock)completedBlock {

    if (![url isKindOfClass:[NSURL class]]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }
    
    __block LRQImageCombinedOperation *operation = [LRQImageCombinedOperation new];
    __weak LRQImageCombinedOperation *weakOperation = operation;
    
    //判断URL是不是failed.
    BOOL isFailed = NO;
    @synchronized (self) {
        if ([self.failedURLs containsObject:url]) {
            isFailed = YES;
        }
    }
    
    if ((url.absoluteString.length == 0) || (!(options & LRQWebImageFailedRetry) && isFailed)) {
        //这里要保证completedBlock执行完后,再进行返回.
        dispatch_main_sync_safe(^{
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil];
            if (completedBlock) {
                completedBlock(nil, error, LRQImageCacheTypeNone, YES, url);
            }
        });
        return operation;
    }
    
    //既然不是错误的url,就把当前操作存储到runningOperation中去.
    @synchronized (self) {
        [self.runningOperations addObject:operation];
    }
    
    NSString *key = [self cacheKeyForURL:url];
    
    weakOperation.cacheOperation = [self.imageCache queryDiskCacheForKey:key done:^(UIImage *image, LRQImageCacheType cacheType) {
        //用到Operation的时候,一定要记住调用isCancelled. 因为现在是多线程,所以对NSMutableArray的操作要加锁.
        if (operation.isCancelled) {
            @synchronized (self) {
                [self.runningOperations removeObject:operation];
            }
            return;
        }
        
        //这里只针对有没有图片,没有判断是否要刷新缓存的处理.
        if (!image || (options & LRQWebImageRefreshCached)) {
            //对 刷新缓存 选项处理省略...
            if (image && options & LRQWebImageRefreshCached) {
                completedBlock(image, nil, cacheType, YES, url);
            }
            
            //通过LRQWebImageOption的枚举值确定LRQWebImageDownloaderOptions的枚举值,大部分功能省略...
            
            //简单设置下载选项.
            LRQWebImageDownloaderOptions downloaderOption = 0;
            
            //简单通过LRQWebImageOption的枚举值 来设置 LRQWebImageDownloaderOptions 的枚举值
            if (options & LRQWebImageProgressiveDownload) { downloaderOption |= LRQWebImageDownloaderProgressiveDownload; }
            
            id <LRQWebImageOperation> subOperation = [self.imageDownloader downloadImageWithURL:url options:downloaderOption progress:progressBlock completed:^(UIImage *downloadedImage, NSData *data, NSError *error, BOOL finished) {
                
                __strong __typeof(weakOperation)strongOperation = weakOperation;
                if (!strongOperation || strongOperation.isCancelled) {
                    //`
                }
                //这里对于Operation的处理 省略...
                else if (error) {
                    if (strongOperation && !strongOperation.isCancelled) {
                        dispatch_main_sync_safe(^{
                            completedBlock(nil, error, LRQImageCacheTypeNone, finished, url);
                        });
                    }
                    //error类型的处理.
                    if (   error.code != NSURLErrorNotConnectedToInternet
                        && error.code != NSURLErrorCancelled
                        && error.code != NSURLErrorTimedOut
                        && error.code != NSURLErrorInternationalRoamingOff
                        && error.code != NSURLErrorDataNotAllowed
                        && error.code != NSURLErrorCannotFindHost
                        && error.code != NSURLErrorCannotConnectToHost) {
                        @synchronized (self) {
                            [self.failedURLs addObject:url];
                        }
                    }
                    
                } else {
                    //省略 从失败URL数组中移除当前URL.
                    if (options & LRQWebImageFailedRetry) {
                        @synchronized (self) {
                            [self.failedURLs removeObject:url];
                        }
                    }
                    
                    BOOL cacheOnDisk = !(options & LRQWebImageCacheMemoryOnly);
                    
                    
                    //这里的if省略了堆animateImages的处理.
                    if (downloadedImage && finished) {
                        [self.imageCache storeImage:downloadedImage recalculateFromImage:NO imageData:nil forKey:key toDisk:cacheOnDisk];
                    }
                    
                    dispatch_main_sync_safe(^{
                        completedBlock(downloadedImage, nil, LRQImageCacheTypeNone, finished, url);
                    })
                }
                //省略将该Operation从run中移除掉的操作.
                if (finished) {
                    @synchronized (self) {
                        [self.runningOperations removeObject:operation];
                    }
                }
            }];
            
            operation.cancelBlock = ^{
                [subOperation cancel];
                
                @synchronized (self.runningOperations) {
                    __strong __typeof(weakOperation) strongOperation = weakOperation;
                    if (strongOperation) {
                        [self.runningOperations removeObject:strongOperation];
                    }
                }
            };
            
        } else if (image) { //获取了缓存中的图片.
            dispatch_main_sync_safe(^{
                __strong __typeof(weakOperation)strongOperation = weakOperation;
                if (strongOperation && !strongOperation.isCancelled) {
                    completedBlock(image, nil, cacheType, YES, url);
                }
            });
            
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
            
        }
    }];
    return operation;
}

@end



@implementation LRQImageCombinedOperation

- (void)setCancelBlock:(LRQWebImageNoParamsBlock)cancelBlock
{
    if (self.isCancelled) {
        if (cancelBlock) {
            cancelBlock();
        }
    } else {
        _cancelBlock = [cancelBlock copy];
    }
}

- (void)cancel
{
    self.cancelled = YES;
    if (self.cacheOperation) {
        [self.cacheOperation cancel];
        self.cacheOperation = nil;
    }
    
    if (self.cancelBlock) {
        self.cancelBlock();
        
        //这样写只是一个临时的解决方法对于: #809.
        _cancelBlock = nil;
    }
}

@end





















