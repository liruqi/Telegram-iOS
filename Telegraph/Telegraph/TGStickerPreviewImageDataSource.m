#import "TGStickerPreviewImageDataSource.h"

#import "TGStringUtils.h"

#import "TGWorkerPool.h"
#import "TGWorkerTask.h"
#import "TGMediaPreviewTask.h"

#import "TGMemoryImageCache.h"

#import "TGImageUtils.h"
#import "TGStringUtils.h"
#import "TGRemoteImageView.h"

#import "TGImageBlur.h"
#import "UIImage+TG.h"
#import "NSObject+TGLock.h"

#import "TGMediaStoreContext.h"

#import "UIImage+WebP.h"
#import "JPNG.h"

#import "TGDocumentMediaAttachment.h"

static TGWorkerPool *workerPool()
{
    static TGWorkerPool *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        instance = [[TGWorkerPool alloc] init];
    });
    
    return instance;
}

static ASQueue *taskManagementQueue()
{
    static ASQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = [[ASQueue alloc] initWithName:"org.telegram.stickerPreviewImageTaskManagementQueue"];
    });
    
    return queue;
}

@implementation TGStickerPreviewImageDataSource

+ (void)load
{
    @autoreleasepool
    {
        [TGImageDataSource registerDataSource:[[self alloc] init]];
    }
}

+ (NSString *)uriPrefix
{
    return @"sticker-preview://?";
}

- (bool)canHandleUri:(NSString *)uri
{
    return [uri hasPrefix:@"sticker-preview://"];
}

- (bool)canHandleAttributeUri:(NSString *)uri
{
    return [uri hasPrefix:@"sticker-preview://"];
}

- (id)loadDataAsyncWithUri:(NSString *)uri progress:(void (^)(float))progress partialCompletion:(void (^)(TGDataResource *resource))__unused partialCompletion completion:(void (^)(TGDataResource *))completion
{
    TGMediaPreviewTask *previewTask = [[TGMediaPreviewTask alloc] init];
    
    [taskManagementQueue() dispatchOnQueue:^
     {
         TGWorkerTask *workerTask = [[TGWorkerTask alloc] initWithBlock:^(bool (^isCancelled)())
         {
             TGDataResource *result = [TGStickerPreviewImageDataSource _performLoad:uri isCancelled:isCancelled];
             
             if (result != nil && progress != nil)
                 progress(1.0f);
             
             if (isCancelled != nil && isCancelled())
                 return;
             
             if (completion != nil)
                 completion(result != nil ? result : [TGStickerPreviewImageDataSource resultForUnavailableImage]);
         }];
         
         if ([TGStickerPreviewImageDataSource _isDataLocallyAvailableForUri:uri])
         {
             [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
         }
         else
         {
             NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[TGStickerPreviewImageDataSource uriPrefix].length]];
             
             if ((![args[@"documentId"] respondsToSelector:@selector(longLongValue)] && ![args[@"localDocumentId"] respondsToSelector:@selector(longLongValue)]) || (![args[@"legacyThumbnailUri"] respondsToSelector:@selector(characterAtIndex:)]) || (![args[@"accessHash"] respondsToSelector:@selector(longLongValue)]) || (![args[@"datacenterId"] respondsToSelector:@selector(intValue)]))
             {
                 if (completion != nil)
                     completion([TGStickerPreviewImageDataSource resultForUnavailableImage]);
             }
             else
             {
                 static NSString *filesDirectory = nil;
                 static dispatch_once_t onceToken;
                 dispatch_once(&onceToken, ^
                 {
                     filesDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0] stringByAppendingPathComponent:@"files"];
                 });
                 
                 NSString *fileDirectoryName = nil;
                 if (args[@"documentId"] != nil)
                 {
                     fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", (int64_t)[args[@"documentId"] longLongValue]];
                 }
                 NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
                 
                 [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
                 
                 NSString *filePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
                 
                 [previewTask executeMultipartWithImageUri:args[@"legacyThumbnailUri"] targetFilePath:filePath progress:^(float value)
                 {
                     if (progress)
                         progress(value);
                 } completion:^(bool success)
                 {
                     if (success)
                     {
                         [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
                     }
                     else
                     {
                         if (completion != nil)
                             completion([TGStickerPreviewImageDataSource resultForUnavailableImage]);
                     }
                 }];
             }
         }
     }];
    
    return previewTask;
}

+ (bool)_isDataLocallyAvailableForUri:(NSString *)uri
{
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[TGStickerPreviewImageDataSource uriPrefix].length]];
    
    if ((![args[@"documentId"] respondsToSelector:@selector(longLongValue)] && ![args[@"localDocumentId"] respondsToSelector:@selector(longLongValue)]) || (![args[@"legacyThumbnailUri"] respondsToSelector:@selector(characterAtIndex:)]))
    {
        return false;
    }
    
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0] stringByAppendingPathComponent:@"files"];
    });
    
    NSString *fileDirectoryName = nil;
    if ([args[@"documentId"] longLongValue] != 0)
        fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", (int64_t)[args[@"documentId"] longLongValue]];
    else
        fileDirectoryName = [[NSString alloc] initWithFormat:@"local%" PRIx64 "", (int64_t)[args[@"localDocumentId"] longLongValue]];
    NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
    
    NSString *filePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NULL])
        return true;
    
    return false;
}

- (void)cancelTaskById:(id)taskId
{
    [taskManagementQueue() dispatchOnQueue:^
     {
         if ([taskId isKindOfClass:[TGMediaPreviewTask class]])
         {
             TGMediaPreviewTask *previewTask = taskId;
             [previewTask cancel];
         }
     }];
}

+ (TGDataResource *)resultForUnavailableImage
{
    return nil;
}

- (id)loadAttributeSyncForUri:(NSString *)__unused uri attribute:(NSString *)attribute
{
    if ([attribute isEqualToString:@"placeholder"])
    {
        return nil;
    }
    
    return nil;
}

- (TGDataResource *)loadDataSyncWithUri:(NSString *)uri canWait:(bool)canWait acceptPartialData:(bool)__unused acceptPartialData asyncTaskId:(__autoreleasing id *)__unused asyncTaskId progress:(void (^)(float))__unused progress partialCompletion:(void (^)(TGDataResource *))__unused partialCompletion completion:(void (^)(TGDataResource *))__unused completion
{
    if (uri == nil)
        return nil;
    
    UIImage *cachedImage = [[TGMediaStoreContext instance] mediaImage:uri attributes:nil];
    if (cachedImage != nil)
        return [[TGDataResource alloc] initWithImage:cachedImage decoded:true];
    
    if (!canWait)
        return nil;
    
    return [TGStickerPreviewImageDataSource _performLoad:uri isCancelled:nil];
}

+ (TGDataResource *)_performLoad:(NSString *)uri isCancelled:(bool (^)())isCancelled
{
    if (isCancelled && isCancelled())
        return nil;
    
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[TGStickerPreviewImageDataSource uriPrefix].length]];
    
    if ((![args[@"documentId"] respondsToSelector:@selector(longLongValue)] && ![args[@"localDocumentId"] respondsToSelector:@selector(longLongValue)]))
    {
        return false;
    }
    
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0] stringByAppendingPathComponent:@"files"];
    });

    NSString *fileDirectoryName = nil;
    if ([args[@"documentId"] longLongValue] != 0)
        fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", (int64_t)[args[@"documentId"] longLongValue]];
    else
        fileDirectoryName = [[NSString alloc] initWithFormat:@"local%" PRIx64 "", (int64_t)[args[@"localDocumentId"] longLongValue]];
    NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
    
    CGSize size = CGSizeMake([args[@"width"] intValue], [args[@"height"] intValue]);
    
    UIImage *thumbnailSourceImage = nil;
    bool lowQualityThumbnail = false;
    
    NSString *filePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
    
    UIImage *image = nil;
    
/*    if ([args[@"mime-type"] hasPrefix:@"image/webp"])
    {
        NSString *cachedFilePath = [fileDirectory stringByAppendingPathComponent:@"cached.bin"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachedFilePath isDirectory:NULL])
        {
            image = [UIImage convertFromGZippedData:cachedFilePath size:size];
        }
        
        if (image != nil)
        {
        }
        else
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NULL])
            {
                __autoreleasing NSData *compressedData = nil;
                image = [UIImage convertFromWebP:filePath compressedData:&compressedData error:nil];
                
                if (compressedData != nil)
                    [compressedData writeToFile:cachedFilePath atomically:true];
            }
        }
    }
    else*/
    {
        NSString *cachedFilePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail.cached.bin"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachedFilePath isDirectory:NULL])
        {
            image = [UIImage convertFromGZippedData:cachedFilePath size:size];
        }
        
        
        image = [[UIImage alloc] initWithContentsOfFile:filePath];
        if (image != nil)
        {
            image = TGScaleImageToPixelSize(image, TGFitSize(image.size, size));
        }
        else
        {
            __autoreleasing NSData *compressedData = nil;
            image = [UIImage convertFromWebP:filePath compressedData:&compressedData error:nil];
            if (compressedData != nil)
                [compressedData writeToFile:cachedFilePath atomically:true];
        }
    }
    
    thumbnailSourceImage = image;
    
    if (thumbnailSourceImage != nil)
    {
        UIImage *thumbnailImage = nil;
        
        thumbnailImage = thumbnailSourceImage;
        
        if (thumbnailImage != nil)
        {
            if (!lowQualityThumbnail)
                [[TGMediaStoreContext instance] setMediaImageForKey:uri image:thumbnailImage attributes:nil];
            
            return [[TGDataResource alloc] initWithImage:thumbnailImage decoded:true];
        }
    }
    
    return nil;
}

@end
