#import "TGAssetImageManager.h"

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "TGMediaPickerAsset.h"

@implementation TGAssetImageManager

+ (NSUInteger)requestImageWithAsset:(TGMediaPickerAsset *)asset
                          imageType:(TGAssetImageType)imageType
                               size:(CGSize)size
                        synchronous:(bool)synchronous
                    completionBlock:(void (^)(UIImage *image, NSError *error))completionBlock
{
    if (asset.backingAsset != nil)
    {
        PHImageRequestOptions *options = [TGAssetImageManager _optionsForAssetImageType:imageType];
        options.synchronous = synchronous;
        PHImageRequestID loadToken;
        
        if (imageType == TGAssetImageTypeFullSize)
        {
            loadToken = [[self imageManager] requestImageDataForAsset:asset.backingAsset
                                                              options:options
                                                        resultHandler:^(NSData *imageData,
                                                                        __unused NSString *dataUTI,
                                                                        __unused UIImageOrientation orientation,
                                                                        __unused NSDictionary *info)
            {
                UIImage *result = [UIImage imageWithData:imageData];
                if (completionBlock)
                    completionBlock(result, nil);
            }];
        }
        else
        {
            loadToken = [[self imageManager] requestImageForAsset:asset.backingAsset
                                                       targetSize:size
                                                      contentMode:PHImageContentModeAspectFill
                                                          options:options
                                                    resultHandler:^(UIImage *result, __unused NSDictionary *info)
            {
                if (completionBlock)
                    completionBlock(result, nil);
            }];
        }
        
        return loadToken;
    }
    else if (asset.backingLegacyAsset != nil)
    {
        switch (imageType)
        {
            case TGAssetImageTypeThumbnail:
                if (completionBlock)
                    completionBlock([UIImage imageWithCGImage:asset.backingLegacyAsset.thumbnail], nil);
                break;

            case TGAssetImageTypeAspectRatioThumbnail:
                if (completionBlock)
                    completionBlock([UIImage imageWithCGImage:asset.backingLegacyAsset.aspectRatioThumbnail], nil);
                break;
                
            case TGAssetImageTypeScreen:
                if (completionBlock)
                    completionBlock([UIImage imageWithCGImage:asset.backingLegacyAsset.defaultRepresentation.fullScreenImage], nil);
                break;
                
            case TGAssetImageTypeFullSize:
                
                break;
                
            default:
                break;
        }
    }
    
    return 0;
}

+ (NSUInteger)requestImageDataWithAsset:(TGMediaPickerAsset *)asset
                        completionBlock:(void (^)(NSData *data, NSError *error))completionBlock
{
    return [self requestImageDataWithAsset:asset synchronous:false completionBlock:completionBlock];
}

+ (NSUInteger)requestImageDataWithAsset:(TGMediaPickerAsset *)asset synchronous:(bool)synchronous
                        completionBlock:(void (^)(NSData *data, NSError *error))completionBlock
{
    if (asset.backingAsset != nil)
    {
        PHImageRequestOptions *options = [TGAssetImageManager _optionsForAssetImageType:TGAssetImageTypeFullSize];
        options.synchronous = synchronous;
        PHImageRequestID loadToken;
        
        loadToken = [[self imageManager] requestImageDataForAsset:asset.backingAsset
                                                          options:options
                                                    resultHandler:^(NSData *imageData,
                                                                    __unused NSString *dataUTI,
                                                                    __unused UIImageOrientation orientation,
                                                                    __unused NSDictionary *info)
        {
            if (completionBlock)
                completionBlock(imageData, nil);
        }];
        
        return loadToken;
    }
    else if (asset.backingLegacyAsset != nil)
    {
        ALAssetRepresentation *defaultRepresentation = asset.backingLegacyAsset.defaultRepresentation;
        NSUInteger size = (NSUInteger)defaultRepresentation.size;
        void *bytes = malloc(size);
        for (NSUInteger offset = 0; offset < size; offset += 256 * 1024)
        {
            [defaultRepresentation getBytes:bytes fromOffset:(long long)offset length:MIN((NSUInteger)256 * 1024, size - offset) error:nil];
        }
        NSData *data = [[NSData alloc] initWithBytesNoCopy:bytes length:size freeWhenDone:true];
        
        if (completionBlock)
            completionBlock(data, nil);
    }
    
    return 0;
}

+ (void)cancelRequestWithToken:(NSUInteger)token
{
    if (iosMajorVersion() < 8)
        return;
    
    [[self imageManager] cancelImageRequest:token];
}

+ (void)startCachingImagesForAssets:(NSArray *)assets size:(CGSize)size imageType:(TGAssetImageType)imageType
{
    if (iosMajorVersion() < 8)
        return;
    
    PHImageRequestOptions *options = [TGAssetImageManager _optionsForAssetImageType:imageType];
    
    NSMutableArray *backingAssets = [NSMutableArray array];
    for (TGMediaPickerAsset *asset in assets)
    {
        if (asset.backingAsset)
            [backingAssets addObject:asset.backingAsset];
    }
    
    [[self imageManager] startCachingImagesForAssets:backingAssets
                                          targetSize:size
                                         contentMode:PHImageContentModeAspectFill
                                             options:options];
}

+ (void)stopCachingImagesForAssets:(NSArray *)assets size:(CGSize)size imageType:(TGAssetImageType)imageType
{
    if (iosMajorVersion() < 8)
        return;
    
    PHImageRequestOptions *options = [TGAssetImageManager _optionsForAssetImageType:imageType];
    
    NSMutableArray *backingAssets = [NSMutableArray array];
    for (TGMediaPickerAsset *asset in assets)
    {
        if (asset.backingAsset)
            [backingAssets addObject:asset.backingAsset];
    }

    [[self imageManager] stopCachingImagesForAssets:backingAssets
                                         targetSize:size
                                        contentMode:PHImageContentModeAspectFill
                                            options:options];
}

+ (void)stopCachingImagesForAllAssets
{
    [[self imageManager] stopCachingImagesForAllAssets];
}

+ (PHImageRequestOptions *)_optionsForAssetImageType:(TGAssetImageType)imageType
{
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    
    switch (imageType)
    {
        case TGAssetImageTypeThumbnail:

            break;
            
        case TGAssetImageTypeAspectRatioThumbnail:
            
            break;
            
        case TGAssetImageTypeScreen:
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.resizeMode = PHImageRequestOptionsResizeModeExact;
            break;
            
        case TGAssetImageTypeFullSize:
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.resizeMode = PHImageRequestOptionsResizeModeNone;
            break;
            
        default:
            break;
    }
    
    return options;
}

+ (PHCachingImageManager *)imageManager
{
    static dispatch_once_t onceToken;
    static PHCachingImageManager *imageManager;
    dispatch_once(&onceToken, ^
    {
        imageManager = [[PHCachingImageManager alloc] init];
    });
    return imageManager;
}

+ (AVPlayerItem *)playerItemForVideoAsset:(TGMediaPickerAsset *)asset
{
    if (asset.backingAsset != nil)
    {
        __block NSConditionLock *syncLock = [[NSConditionLock alloc] initWithCondition:1];
        __block AVPlayerItem *avPlayerItem;
        
        [[self imageManager] requestPlayerItemForVideo:asset.backingAsset
                                               options:nil
                                         resultHandler:^(AVPlayerItem *playerItem, __unused NSDictionary *info)
        {
            avPlayerItem = playerItem;
            
            [syncLock lock];
            [syncLock unlockWithCondition:0];
        }];
        
        [syncLock lockWhenCondition:0];
        [syncLock unlock];
        
        return avPlayerItem;
    }
    else if (asset.backingLegacyAsset != nil)
    {
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:asset.url];
        return item;
    }
    
    return nil;
}

+ (AVAsset *)avAssetForVideoAsset:(TGMediaPickerAsset *)asset
{
    if (asset.backingAsset != nil)
    {
        __block NSConditionLock *syncLock = [[NSConditionLock alloc] initWithCondition:1];
        __block AVAsset *avAsset;
        
        [[self imageManager] requestAVAssetForVideo:asset.backingAsset
                                            options:nil
                                      resultHandler:^(AVAsset *asset, __unused AVAudioMix *audioMix, __unused NSDictionary *info)
        {
            avAsset = asset;
            
            [syncLock lock];
            [syncLock unlockWithCondition:0];
        }];
        
        [syncLock lockWhenCondition:0];
        [syncLock unlock];
        
        return avAsset;
    }
    else if (asset.backingLegacyAsset != nil)
    {
        return [[AVURLAsset alloc] initWithURL:asset.url options:nil];
    }
    
    return nil;
}

@end
