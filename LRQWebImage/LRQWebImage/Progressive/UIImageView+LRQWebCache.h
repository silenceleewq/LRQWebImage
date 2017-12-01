//
//  UIImageView+LRQWebCache.h
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/28.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LRQWebImageManager.h"

@interface UIImageView (LRQWebCache)

- (void)lrq_setImageWithURL:(NSURL *)url;

- (void)lrq_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(LRQWebImageOptions)options progress:(LRQWebImageDownloaderProgressBlock)progressBlock completed:(LRQWebImageCompletionWithFinishedBlock)completedBlock;

@end
