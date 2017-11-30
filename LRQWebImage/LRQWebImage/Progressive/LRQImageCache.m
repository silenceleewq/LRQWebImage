//
//  LRQImageCache.m
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/28.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import "LRQImageCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface AutoPurgeCache: NSCache
@end

@implementation AutoPurgeCache
- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}
@end

static unsigned char kPNGSignatureBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
static NSData *kPNGSignatureData = nil;
BOOL ImageDataHasPNGPreffix(NSData *data)
{
    NSUInteger pngSignatureLength = [kPNGSignatureData length];
    if ([data length] > pngSignatureLength) {
        if ([[data subdataWithRange:NSMakeRange(0, pngSignatureLength)] isEqualToData:kPNGSignatureData]) {
            return YES;
        }
    }
    return NO;
}

FOUNDATION_STATIC_INLINE NSUInteger LRQCacheCostForImage(UIImage *image) {
    return image.size.height * image.size.width * image.scale * image.scale;
}

@interface LRQImageCache ()

@property (strong, nonatomic) NSCache *memCache;
@property (copy, nonatomic) NSString *diskCachePath;
@property (strong, nonatomic) dispatch_queue_t ioQueue;

@end

@implementation LRQImageCache {
    NSFileManager *_fileManager;
}

+ (LRQImageCache *)sharedImageCache
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init
{
    return [self initWithNamespace:@"default"];
}

- (id)initWithNamespace:(NSString *)ns
{
    NSString *path = [self makeDiskCachePath:ns];
    return [self initWithNamespace:ns diskCacheDirectory:path];
}

- (id)initWithNamespace:(NSString *)ns diskCacheDirectory:(NSString *)directory
{
    self = [super init];
    if (self) {
        NSString *fullNameSpace = [@"com.lrq.LRQWebImageCache" stringByAppendingString:ns];
        
        //实例化ioQueue
        _ioQueue = dispatch_queue_create("com.lrq.LRQWebImageCache", DISPATCH_QUEUE_SERIAL);
        
        //实例化memCache
        _memCache = [[AutoPurgeCache alloc] init];
        _memCache.name = fullNameSpace;
        
        _shouldCacheImagesInMemory = YES;
        kPNGSignatureData = [NSData dataWithBytes:kPNGSignatureBytes length:8];
        
        //初始化diskPath
        if (directory) {
            _diskCachePath = [directory stringByAppendingPathComponent:fullNameSpace];
        } else {
            directory = [self makeDiskCachePath:ns];
            _diskCachePath = [directory stringByAppendingPathComponent:fullNameSpace];
        }
        
        //初始化文件管理对象
        dispatch_sync(_ioQueue, ^{
            _fileManager = [NSFileManager new];
        });
        
        //添加通知
    }
    
    return self;
}

- (void)dealloc
{

}

- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path
{
    NSString *fileName = [self cachedFileNameForKey:key];
    return [path stringByAppendingPathComponent:fileName];
}

- (NSString *)defualtCachePathForkey:(NSString *)key
{
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

#pragma mark - LRQImageCache (private)
- (NSString *)cachedFileNameForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    
    NSString * fileName = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@", r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15], [[key pathExtension] isEqualToString: @""] ? @"": [key pathExtension]];
    
    return fileName;
}

#pragma mark - ImageCache

- (NSString *)makeDiskCachePath:(NSString *)fullNameSpace
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:fullNameSpace];
}

//这里主要就是将图片存储到内存当中,并且对图片进行重新处理.将图片以data的形式直接存储到硬盘上去.
- (void)storeImage:(UIImage *)image recalculateFromImage:(BOOL)recalculate imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk
{
    if (!image || !key) { return; }
    
    if (self.shouldCacheImagesInMemory) {
        NSUInteger cost = LRQCacheCostForImage(image);
        [self.memCache setObject:image forKey:key cost:cost];
    }
    
    if (toDisk) {
        dispatch_async(_ioQueue, ^{
            NSData *data = imageData;
            if (image && (recalculate || !data)) {
                int alphaInfo = CGImageGetAlphaInfo(image.CGImage);
                BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                                  alphaInfo == kCGImageAlphaNoneSkipLast ||
                                  alphaInfo == kCGImageAlphaNoneSkipFirst);
                BOOL imageIsPNG = hasAlpha; //如果没有imageData的话,那么就直接根据这一结果来判断是否是PNG图片.
                
                if ([imageData length] >= [kPNGSignatureData length]) {
                    imageIsPNG = ImageDataHasPNGPreffix(imageData);
                }
                
                if (imageIsPNG) {
                    data = UIImagePNGRepresentation(image);
                } else {
                    data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
                }
            }
            [self storeImageDataToDisk:data forKey:key];
        });
    }
}


- (void)storeImage:(UIImage *)image forKey:(NSString *)key
{
    [self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:YES];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk
{
    [self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:toDisk];
}

- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key
{
    //首先是错误处理
    if (!imageData) { return; }
    
    //创建存储路径
    if (_fileManager) {
        [_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //获取默认的文件路径
    NSString *cachePathForKey = [self defualtCachePathForkey:key];
    
    //根据上述路径创建文件
    [_fileManager createFileAtPath:cachePathForKey contents:imageData attributes:nil];
}

- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key
{
    return [self.memCache objectForKey:key];
}

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key
{
    //首先查找内存当中
    UIImage *image = [self.memCache objectForKey:key];
    if (image) {
        return image;
    }
    
    //去 disk 中查找, 这里意味着内存里面没有,要记得缓存到内存中去.
    UIImage *diskImage = [self diskImageForKey:key];
    if (diskImage && self.shouldCacheImagesInMemory) {
        NSInteger cost = LRQCacheCostForImage(diskImage);
        [self.memCache setObject:diskImage forKey:key cost:cost];
    }
    
    return image;
}

- (UIImage *)diskImageForKey:(NSString *)key
{
    NSData *data = [self diskImageDataBySearchingAllPathsForKey:key];
    if (data) {
        /**
         这里省略了
         对图片data的格式处理
         对图片的缩放处理.
         对图片的压缩处理.
         */
        return [UIImage imageWithData:data];
    }
    return nil;
}

- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key
{
    NSString *defaultPath = [self defualtCachePathForkey:key];
    NSData *data = [NSData dataWithContentsOfFile:defaultPath];
    
    if (data) {
        return data;
    }
    
    data = [NSData dataWithContentsOfFile:[defaultPath stringByDeletingPathExtension]];
    if (data) {
        return data;
    }
    
    /**
     这里省略了去用户自定义的路径里面查找data
     */
    
    return nil;
}

- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(LRQWebImageQueryCompletedBlock)doneBlock
{
    if (!key) {
        return nil;
    }
    
    if (!doneBlock) {
        return nil;
    }
    
    //首先从内存中取
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image) {
        doneBlock(image, LRQImageCacheTypeMemory);
        return nil;
    }
    
    __block NSOperation *operation = [NSOperation new];
    
    //然后去一个队列中,异步取图片, 和上面的步骤一样,只不过多了一个异步而已.
    dispatch_async(_ioQueue, ^{
        if ([operation isCancelled]) {
            return;
        }
        
        @autoreleasepool {
            UIImage *diskImage = [self diskImageForKey:key];
            
            if (diskImage && self.shouldCacheImagesInMemory) {
                NSUInteger cost = LRQCacheCostForImage(diskImage);
                [self.memCache setObject:diskImage forKey:key cost:cost];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                doneBlock(image, LRQImageCacheTypeDisk);
            });
        }
        
    });
    return operation;
    
}



@end
























