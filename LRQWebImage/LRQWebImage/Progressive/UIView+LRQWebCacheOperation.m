//
//  UIView+LRQWebCacheOperation.m
//  LRQWebImage
//
//  Created by lirenqiang on 2017/12/1.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import "UIView+LRQWebCacheOperation.h"
#import <objc/runtime.h>
#import "LRQWebImageOperation.h"
static char kcacheOperationKey;

@implementation UIView (LRQWebCacheOperation)

- (NSMutableDictionary *)operationDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, &kcacheOperationKey);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &kcacheOperationKey, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (void)lrq_setImageLoadOperation:(id)operation forKey:(NSString *)key
{
    NSLog(@"添加----Operation---key: %@, self: %@", key, self);
    [self lrq_cancelImageLoadOperationWithKey:key];
    NSMutableDictionary *operationDict = [self operationDictionary];
    [operationDict setObject:operation forKey:key];
}

- (void)lrq_removeImageLoadOperationWithKey:(NSString *)key
{
    
    NSMutableDictionary *operationDict = [self operationDictionary];
    [operationDict removeObjectForKey:key];
}

- (void)lrq_cancelImageLoadOperationWithKey:(NSString *)key
{
    
    NSMutableDictionary *operationDict = [self operationDictionary];
    id operation = operationDict[key];
    if ([operation conformsToProtocol:@protocol(LRQWebImageOperation)]) {
        [(id<LRQWebImageOperation>)operation cancel];
    }
    [self lrq_removeImageLoadOperationWithKey:key];
}

@end

/**
 首先是初始化了一个NSMutableDictionary来存储每个Operation.
 
 setimageload method:
    需要先取消掉当前的操作.
    取出Operation, url做为key,Operation作为value.
 
 cancel,首先根据key取出Operation,然后执行cancel,最后移除该Operation.
 */
























