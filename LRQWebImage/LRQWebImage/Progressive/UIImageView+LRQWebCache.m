//
//  UIImageView+LRQWebCache.m
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/28.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import "UIImageView+LRQWebCache.h"
#import "UIView+LRQWebCacheOperation.h"

@implementation UIImageView (LRQWebCache)

- (void)lrq_setImageWithURL:(NSURL *)url
{
    [self lrq_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)lrq_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(LRQWebImageOptions)options progress:(LRQWebImageDownloaderProgressBlock)progressBlock completed:(LRQWebImageCompletionWithFinishedBlock)completedBlock
{
    
    [self lrq_cancelCurrentImageLoad];
    
    if (placeholder) {
        self.image = placeholder;
    }
    if (url) {
        __weak typeof(self) wself = self;
        
        id <LRQWebImageOperation> operation = [[LRQWebImageManager sharedManager] downloadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, LRQImageCacheType type, BOOL finished, NSURL *imageURL) {
            if (!wself) {
                return;
            }
            dispatch_main_sync_safe(^{
                if (image) {
                    self.image = image;
                    [wself setNeedsLayout];
                }
                
                if (completedBlock) {
                    completedBlock(image, error, type, finished, url);
                }
            });
        }];
        [self lrq_setImageLoadOperation:operation forKey:@"UIImageViewImageLoad"];
    } else {
        dispatch_main_async_safe(^{
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil];
                completedBlock(nil, error, LRQImageCacheTypeNone, YES, url);
            }
        });
    }
    
}

- (void)lrq_cancelCurrentImageLoad
{
    [self lrq_cancelImageLoadOperationWithKey:@"UIImageViewImageLoad"];
}




@end
























