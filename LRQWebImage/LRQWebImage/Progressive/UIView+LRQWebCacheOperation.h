//
//  UIView+LRQWebCacheOperation.h
//  LRQWebImage
//
//  Created by lirenqiang on 2017/12/1.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (LRQWebCacheOperation)

- (void)lrq_setImageLoadOperation:(id)operation forKey:(NSString *)key;

- (void)lrq_cancelImageLoadOperationWithKey:(NSString *)key;

- (void)lrq_removeImageLoadOperationWithKey:(NSString *)key;

@end
