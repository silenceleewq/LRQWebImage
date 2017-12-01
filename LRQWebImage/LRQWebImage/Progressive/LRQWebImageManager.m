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

@end

@interface LRQWebImageManager ()

@property (strong, nonatomic) LRQImageCache *imageCache;
@property (strong, nonatomic) LRQWebImageDownloader *imageDownloader;
@property (strong, nonatomic) NSSet *failedURLs;
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
        _failedURLs = [NSSet new];
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

- (void)downloadImageWithURL:(NSURL *)url options:(LRQWebImageOptions)options progress:(LRQWebImageDownloaderProgressBlock)progressBlock completed:(LRQWebImageCompletionWithFinishedBlock)completedBlock {

    if (![url isKindOfClass:[NSURL class]]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }
    
    NSString *key = [self cacheKeyForURL:url];
    
    [self.imageCache queryDiskCacheForKey:key done:^(UIImage *image, LRQImageCacheType cacheType) {
        //这里只针对有没有图片,没有判断是否要刷新缓存的处理.
        if (!image) {
            //对 刷新缓存 选项处理省略...
            
            //通过LRQWebImageOption的枚举值确定LRQWebImageDownloaderOptions的枚举值,大部分功能省略...
            
            //简单设置下载选项.
            LRQWebImageDownloaderOptions downloaderOption = 0;
            
            //简单通过LRQWebImageOption的枚举值 来设置 LRQWebImageDownloaderOptions 的枚举值
            if (options & LRQWebImageProgressiveDownload) { downloaderOption |= LRQWebImageDownloaderProgressiveDownload; }
            
            [self.imageDownloader downloadImageWithURL:url options:downloaderOption progress:progressBlock completed:^(UIImage *downloadedImage, NSData *data, NSError *error, BOOL finished) {
                //这里对于Operation的处理 省略...
                if (error) {
                    dispatch_main_sync_safe(^{
                        completedBlock(nil, error, LRQImageCacheTypeNone, finished, url);
                    });
                    
                    //省略了堆error类型的处理.
                } else {
                    //省略 从失败URL数组中移除当前URL.
                    
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
                
            }];
            
        } else if (image) {
            dispatch_main_sync_safe(^{
               completedBlock(image, nil, LRQImageCacheTypeNone, YES, url);
            });
        }
    }];

}

@end
























