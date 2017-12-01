//
//  LRQImageDonwloader.h
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/27.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LRQWebImageOperation.h"

extern NSString *const LRQWebImageErrorDomain;

typedef NS_OPTIONS(NSUInteger, LRQWebImageDownloaderOptions){
    LRQWebImageDownloaderProgressiveDownload = 1 << 1,
    LRQWebImageDownloaderIgnoreCacheResponse = 1 << 3,
};

typedef void(^LRQWebImageDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);
typedef void(^LRQWebImageDownloaderCompletedBlock)(UIImage *image, NSData *data, NSError *error, BOOL finished);
typedef void(^LRQWebImageDownloaderNoParamsBlock)(void);


@interface LRQWebImageDownloader : NSObject

@property (assign, nonatomic) NSTimeInterval downloadTimeout;

+ (instancetype)sharedDonwloader;

- (id <LRQWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(LRQWebImageDownloaderOptions)options progress:(LRQWebImageDownloaderProgressBlock)progressBlock completed:(LRQWebImageDownloaderCompletedBlock)completedBlock;

@end
























