#import <Foundation/Foundation.h>

@class TGMediaPickerAsset;
@class AVPlayerItem;
@class AVAsset;

typedef enum {
    TGAssetImageTypeUndefined = 0,
    TGAssetImageTypeThumbnail,
    TGAssetImageTypeAspectRatioThumbnail,
    TGAssetImageTypeScreen,
    TGAssetImageTypeFullSize
} TGAssetImageType;

@interface TGAssetImageManager : NSObject

+ (NSUInteger)requestImageWithAsset:(TGMediaPickerAsset *)asset
                          imageType:(TGAssetImageType)imageType
                               size:(CGSize)size
                        synchronous:(bool)synchronous
                    completionBlock:(void (^)(UIImage *image, NSError *error))completionBlock;

+ (NSUInteger)requestImageDataWithAsset:(TGMediaPickerAsset *)asset
                    completionBlock:(void (^)(NSData *data, NSError *error))completionBlock;
+ (NSUInteger)requestImageDataWithAsset:(TGMediaPickerAsset *)asset synchronous:(bool)synchronous
                        completionBlock:(void (^)(NSData *data, NSError *error))completionBlock;

+ (void)cancelRequestWithToken:(NSUInteger)token;

+ (void)startCachingImagesForAssets:(NSArray *)assets
                               size:(CGSize)size
                          imageType:(TGAssetImageType)imageType;

+ (void)stopCachingImagesForAssets:(NSArray *)assets
                              size:(CGSize)size
                         imageType:(TGAssetImageType)imageType;

+ (void)stopCachingImagesForAllAssets;

+ (AVPlayerItem *)playerItemForVideoAsset:(TGMediaPickerAsset *)asset;
+ (AVAsset *)avAssetForVideoAsset:(TGMediaPickerAsset *)asset;

@end
