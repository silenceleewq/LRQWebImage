//
//  UIImageView+LRQWebCache.m
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/28.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import "UIImageView+LRQWebCache.h"

@implementation UIImageView (LRQWebCache)

- (void)lrq_setImageWithURL:(NSURL *)url
{
    [self lrq_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)lrq_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(LRQWebImageOptions)options progress:(LRQWebImageDownloaderProgressBlock)progressBlock completed:(LRQWebImageDownloaderCompletedBlock)completedBlock
{
    
    if (placeholder) {
        self.image = placeholder;
    }
    if (url) {
        __weak typeof(self) wself = self;
        
        [[LRQWebImageManager sharedManager] downloadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, LRQImageCacheType type, BOOL finished, NSURL *imageURL) {
            if (!wself) {
                return;
            }
            if (image) {
                dispatch_main_sync_safe(^{
                    self.image = image;
                });
            }
        }];
        
    }
    
}


@end
























