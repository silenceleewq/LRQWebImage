//
//  LRQImageCache.h
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/28.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LRQImageCacheType) {
    
    LRQImageCacheTypeNone,
    
    LRQImageCacheTypeDisk,
    
    LRQImageCacheTypeMemory
};

typedef void(^LRQWebImageQueryCompletedBlock)(UIImage *image, LRQImageCacheType cacheType);
typedef void(^LRQWebImageNoParamsBlock)(void);

@interface LRQImageCache : NSObject

@property (assign, nonatomic) BOOL shouldCacheImagesInMemory;

+ (LRQImageCache *)sharedImageCache;

- (id)initWithNamespace:(NSString *)ns;

- (id)initWithNamespace:(NSString *)ns diskCacheDirectory:(NSString *)directory;

- (void)storeImage:(UIImage *)image forKey:(NSString *)key;

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk;

- (void)storeImage:(UIImage *)image recalculateFromImage:(BOOL)recalculate imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk;

- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key;

///异步查询磁盘缓存中的图片.
- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(LRQWebImageQueryCompletedBlock)doneBlock;

- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key;

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key;

- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key;

- (void)removeImageForKey:(NSString *)key;

- (void)removeImageForKey:(NSString *)key withCompletion:(LRQWebImageNoParamsBlock)completion;

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk;

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(LRQWebImageNoParamsBlock)completion;
@end
