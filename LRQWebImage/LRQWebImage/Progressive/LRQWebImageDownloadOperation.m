//
//  LRQImageDownloadOperation.m
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/27.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import "LRQWebImageDownloadOperation.h"

NSString *const LRQWebImageDownloadStartNotification = @"LRQWebImageDownloadStartNotification";
NSString *const LRQWebImageDownloadReceiveResponseNotification = @"LRQWebImageDownloadReceiveResponseNotification";
NSString *const LRQWebImageDownloadStopNotification = @"LRQWebImageDownloadStopNotification";
NSString *const LRQWebImageDownloadFinishNotification = @"LRQWebImageDownloadFinishNotification";

@interface LRQWebImageDownloadOperation () {
    BOOL responseFromCached; //是否有缓存
}

@property (copy, nonatomic) LRQWebImageDownloaderProgressBlock progressBlock;
@property (copy, nonatomic) LRQWebImageDownloaderCompletedBlock completedBlock;
@property (copy, nonatomic) LRQWebImageDownloaderNoParamsBlock cancelBlock;

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (nonatomic, strong) NSMutableData *imageData;

@property (weak, nonatomic) NSURLSession *unownedSession;
@property (strong, nonatomic) NSURLSession *ownedSession;

@property (strong, nonatomic) NSURLSessionDataTask *dataTask;

@property (strong, nonatomic) NSThread *thread;

@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

@end

@implementation LRQWebImageDownloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (id)initWithRequest:(NSURLRequest *)request
            inSession:(NSURLSession *)session
              options:(LRQWebImageDownloaderOptions)options
             progress:(LRQWebImageDownloaderProgressBlock)progressBlock
            completed:(LRQWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(LRQWebImageDownloaderNoParamsBlock)cancelBlock
{
    if ((self = [super init])) {
        _request = [request copy];
        _shouldDecompressImages = YES;
        _options = options;
        _progressBlock = [progressBlock copy];
        _completedBlock = [completedBlock copy];
        _cancelBlock = [cancelBlock copy];
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
        _unownedSession = session;
        responseFromCached = YES;
    }
    return self;
}

- (void)start
{
    @synchronized(self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
        if (hasApplication && [self shouldContinueWhenAppEnterBackground]) {
            __weak __typeof__ (self) wself = self;
            UIApplication *app = [UIApplicationClass performSelector:@selector(sharedApplication)];;
            self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
                __strong __typeof (wself) sself = self;
                
                if (sself) {
                    [sself cancel];
                    [app endBackgroundTask:self.backgroundTaskId];
                    self.backgroundTaskId = UIBackgroundTaskInvalid;
                }
            }];
            
        }
#endif
        NSURLSession *session = self.unownedSession;
        if (!session) {
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.timeoutIntervalForRequest = 15;
            self.ownedSession = [NSURLSession sessionWithConfiguration:config
                                                              delegate:self
                                                         delegateQueue:nil];
            session = self.ownedSession;
        }
        self.dataTask = [session dataTaskWithRequest:self.request];
        self.executing = YES;
        self.thread = [NSThread currentThread];
    }
    
    [self.dataTask resume];
    
    if (self.dataTask) {
        if (self.progressBlock) {
            self.progressBlock(0, NSURLResponseUnknownLength);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName: LRQWebImageDownloadStartNotification object:self];
        });
    } else {
        if (self.completedBlock) {
            self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"Connection can't be initialized"}], YES);
        }
    }
    
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IHPONE_4_0
    //不明白为什么这里还要再设置一次.
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if (!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) { return; }
    
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        UIApplication *app = [UIApplicationClass performSelector:@selector(sharedApplication)];
        [app endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
#endif
    
}

- (void)cancel {
    @synchronized (self) {
        //不明白这里的意思
        if (self.thread) {
            [self performSelector:@selector(cancelInternal) onThread:self.thread withObject:nil waitUntilDone:NO];
        } else {
            [self cancelInternal];
        }
    }
}

//不明白为什么要写这样方法.
- (void)cancelInternalAndStop {
    if (self.isFinished) {
        return;
    }
    
    [self cancelInternal];
}

- (void)cancelInternal {
    if (self.isFinished) { return; }
    [super cancel];
    if (self.cancelBlock) {
        self.cancelBlock();
    }
    
    if (self.dataTask) {
        [self.dataTask cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadStopNotification object:self];
        });
        if (!self.isFinished) { self.finished = YES; }
        if (self.isExecuting) { self.executing = NO; }
    }
    
    [self reset];
}

- (void)reset {
    self.cancelBlock = nil;
    self.completionBlock = nil;
    self.progressBlock = nil;
    self.dataTask = nil;
    self.imageData = nil;
    self.thread = nil;
    if (self.ownedSession) {
        [self.ownedSession invalidateAndCancel];
        self.ownedSession = nil;
    }
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent
{
    return YES;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    if (![response respondsToSelector:@selector(statusCode)] || ([(NSHTTPURLResponse*)response statusCode] < 400 && [(NSHTTPURLResponse *)response statusCode] != 304)) {
        //获取图片总的大小
        NSInteger expectedSize = response.expectedContentLength ? response.expectedContentLength : 0;
        self.expectedSize = expectedSize;
        //调用progressBlock
        if (self.progressBlock) {
            self.progressBlock(0, expectedSize);
        }
        //初始化imagedata
        self.imageData = [NSMutableData dataWithCapacity:expectedSize];
        //赋值URLResponse
        self.response = response;
        //发送通知.
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadReceiveResponseNotification object:self];
        });
    } else {
        NSUInteger code = [(NSHTTPURLResponse *)response statusCode];
        if (304 == code) {
            [self cancelInternalAndStop];
        } else {
            [self.dataTask cancel];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadStopNotification object:self];
        });
        
        if (self.completedBlock) {
            self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:[(NSHTTPURLResponse *)response statusCode] userInfo:nil], YES);
        }
        
        [self done];
    }
    
    //调用 completionHandler
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    //开始接收数据,对数据进行拼接.
    [self.imageData appendData:data];
    NSLog(@"data.length: %zd", data.length);
    // 如果开启了 progressive 选项, expectedSize大于0,并且实现了completedBlock,那么就生成图片,调用completedBlock
    if ((self.options & LRQWebImageDownloaderProgressiveDownload) && (self.expectedSize > 0) && self.completedBlock) {
        UIImage *image = [UIImage imageWithData:self.imageData];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.completedBlock) {
                self.completedBlock(image, nil, nil, NO);
            }
        });
    }
    //调用progressBlock.
    if (self.progressBlock) {
        self.progressBlock(self.imageData.length, self.expectedSize);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler
{
    responseFromCached = NO; //if this method is called, it means that the response wasn't read from cache.
    
    //初始化 completionHandler 需要的对象 NSCachedURLResponse.
    NSCachedURLResponse *cachedResponse = proposedResponse;
    //判断request的设置是否忽略缓存.
    if (self.request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
        cachedResponse = nil;
    }
    //调用 completionHandler
    completionHandler(cachedResponse);
}

#pragma mark - NSURLSessionTaskDelegate
//这个error不包括server断的,只是client端的错误
//这个方法表示数据传输完成,成功,error为nil.
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    //使用锁,将thread, datatask置为nil, 并且发送stop通知,如果没有error,再发送一个finish通知.
    @synchronized(self) {
        self.thread = nil;
        self.dataTask = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadStopNotification object:self];
        });
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadFinishNotification object:self];
            });
        }
    }
    
    //如果有错误,直接完成,将error输出. 上面只是根据error发送通知,这里才是处理error.
    if (error) {
        if (self.completedBlock) {
            self.completedBlock(nil, nil, error, YES);
        }
    } else {
        LRQWebImageDownloaderCompletedBlock completionBlock = self.completedBlock;
        //没有的话,判断是否有completedBlock,
        if (completionBlock) {
            //有completedBlock, 判断imageData.如果没有imagedata,直接返回错误.
            if (self.imageData) {
                
                UIImage *image = [UIImage imageWithData:self.imageData];
                
                //判断图片的size是否为CGSizeZero.
                if (CGSizeEqualToSize(CGSizeZero, image.size)) {
                    completionBlock(nil, nil, [NSError errorWithDomain:LRQWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"downloaded image has 0 pixels."}], YES);
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionBlock(image, self.imageData, nil, YES);
                    });
                }
                
            } else {
                completionBlock(nil, nil, [NSError errorWithDomain:LRQWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"image data is nil"}], YES);
            }
        }
    }
    
    self.completionBlock = nil;
    [self done];
    
}

/////这个不太懂..先不搞这个了..
//- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
//{
//
//}


- (BOOL)shouldContinueWhenAppEnterBackground {
    return self.options & LRQWebImageDownloaderProgressiveDownload;
}

@end
























