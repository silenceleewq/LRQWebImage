//
//  LRQImageDownloadOperation.h
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/27.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LRQWebImageDownloader.h"
#import "LRQWebImageOperation.h"

extern NSString *const LRQWebImageDownloadStartNotification;
extern NSString *const LRQWebImageDownloadReceiveResponseNotification;
extern NSString *const LRQWebImageDownloadStopNotification;
extern NSString *const LRQWebImageDownloadFinishNotification;

@interface LRQWebImageDownloadOperation : NSOperation <LRQWebImageOperation, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic, readonly) NSURLRequest *request;

@property (strong, nonatomic, readonly) NSURLSessionTask *dataTask;

@property (assign, nonatomic) BOOL shouldDecompressImages;

@property (assign, nonatomic) NSInteger expectedSize;

@property (strong, nonatomic) NSURLResponse *response;

@property (assign, nonatomic, readonly) LRQWebImageDownloaderOptions options;

/**
 初始化一个 SDWebImageDownloaderOperation 对象.

 @param request             the URL request
 @param session             the URL session in which this operation will run
 @param options              downloader options
 @param progressBlock       the block executed when a new chunk data arrives.
                            @note the progress block is executed on a background queue
 @param completedBlock      the block executed when the download is done
                            @note the completedBlock will executed on the main queue for success.If errors are found, there is a chance the block will be executed on a background queue
 @param cancelBlock         the block executed if the download (operation) is cancelled.
 @return the initialized instance
 */
- (id)initWithRequest:(NSURLRequest *)request
            inSession:(NSURLSession *)session
              options:(LRQWebImageDownloaderOptions)options
             progress:(LRQWebImageDownloaderProgressBlock)progressBlock
            completed:(LRQWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(LRQWebImageDownloaderNoParamsBlock)cancelBlock;

@end
























