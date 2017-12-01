//
//  LRQWebImageManager.h
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/28.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LRQImageCache.h"
#import "LRQWebImageDownloader.h"

#define dispatch_main_sync_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }
#define dispatch_main_async_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }

typedef NS_OPTIONS(NSUInteger, LRQWebImageOptions) {
    LRQWebImageFailedRetry = 1 << 0,
    LRQWebImageCacheMemoryOnly = 1 << 2,
    LRQWebImageProgressiveDownload = 1 << 3,
    LRQWebImageRefreshCached = 1 << 4,
};

typedef NSString *(^LRQWebImageCacheKeyFilterBlock)(NSURL *url);
typedef void(^LRQWebImageCompletionWithFinishedBlock)(UIImage *image, NSError *error, LRQImageCacheType type, BOOL finished, NSURL  *imageURL);

@interface LRQWebImageManager : NSObject


@property (copy, nonatomic) LRQWebImageCacheKeyFilterBlock filterBlock;

+ (instancetype)sharedManager;

- (instancetype)initWithCache:(LRQImageCache *)cache downloader:(LRQWebImageDownloader *)downloader;

- (id <LRQWebImageOperation>)downloadImageWithURL:(NSURL *)url
                     options:(LRQWebImageOptions)options
                    progress:(LRQWebImageDownloaderProgressBlock)progressBlock
                   completed:(LRQWebImageCompletionWithFinishedBlock)completedBlock;


@end
