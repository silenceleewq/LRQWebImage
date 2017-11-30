//
//  LRQImageDonwloader.m
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/27.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import "LRQWebImageDownloader.h"
#import "LRQWebImageDownloadOperation.h"
NSString *const LRQWebImageErrorDomain = @"LRQWebImageErrorDomain";

static LRQWebImageDownloader *_downloader = nil;

@interface LRQWebImageDownloader () <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic) Class operationClass;
@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSOperationQueue *downloadQueue;
@end

@implementation LRQWebImageDownloader

+ (instancetype)sharedDonwloader
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloader = [[LRQWebImageDownloader alloc] init];
    });
    return _downloader;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationClass = [LRQWebImageDownloadOperation class];
        _downloadTimeout = 15;
        _downloadQueue =  [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 6;
        
        //实例化session
        NSURLSessionConfiguration *configure = [NSURLSessionConfiguration defaultSessionConfiguration];
        configure.timeoutIntervalForRequest = _downloadTimeout;
        _session = [NSURLSession sessionWithConfiguration:configure
                                                 delegate:self
                                            delegateQueue:nil];
        
    }
    return self;
}

//- (void)downloadImageWithURL:(NSURL *)url completed:(LRQWebImageDownloaderCompletedBlock)completed
//{
//    __block LRQWebImageDownloadOperation *operation;
//    
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    request.HTTPShouldUsePipelining = YES;
//    
//    operation = [[self.operationClass alloc] initWithRequest:request inSession:self.session options:LRQWebImageDownloaderProgressiveDownload progress:^(NSInteger receivedSize, NSInteger expectedSize) {
//        NSLog(@"receivedSize: %zd, expectedSize: %zd", receivedSize, expectedSize);
//    } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
//        if (error) {
//            completed(nil, nil, error, YES);
//        } else {
//            completed(image, data, nil, YES);
//        }
//    } cancelled:nil];
//    
//    [self.downloadQueue addOperation:operation];
//}

- (void)downloadImageWithURL:(NSURL *)url options:(LRQWebImageDownloaderOptions)options progress:(LRQWebImageDownloaderProgressBlock)progressBlock completed:(LRQWebImageDownloaderCompletedBlock)completedBlock {
    __block LRQWebImageDownloadOperation *operation;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPShouldUsePipelining = YES;
    
    operation = [[self.operationClass alloc] initWithRequest:request inSession:self.session options:LRQWebImageDownloaderProgressiveDownload progress:^(NSInteger receivedSize, NSInteger expectedSize) {
    } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
        if (error) {
            completedBlock(nil, nil, error, YES);
        } else {
            completedBlock(image, data, nil, YES);
        }
    } cancelled:nil];
    
    [self.downloadQueue addOperation:operation];
}

- (LRQWebImageDownloadOperation *)operationWithTask:(NSURLSessionTask *)task
{
    LRQWebImageDownloadOperation *returnOperation = nil;
    for (LRQWebImageDownloadOperation *operation in self.downloadQueue.operations) {
        if (operation.dataTask.taskIdentifier == task.taskIdentifier) {
            returnOperation = operation;
            break;
        }
    }
    return returnOperation;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    LRQWebImageDownloadOperation *dataOperation = [self operationWithTask:dataTask];
    [dataOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    LRQWebImageDownloadOperation *dataOperation = [self operationWithTask:dataTask];
    [dataOperation URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler
{
    LRQWebImageDownloadOperation *dataOperation = [self operationWithTask:dataTask];
    [dataOperation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
}

#pragma mark - NSURLSessionTaskDelegate
//这个error不包括server断的,只是client端的错误
//这个方法表示数据传输完成,成功,error为nil.
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    LRQWebImageDownloadOperation *dataOperation = [self operationWithTask:task];
    [dataOperation URLSession:session task:task didCompleteWithError:error];
}





@end
























