#import <Foundation/Foundation.h>

@class TGMediaPickerAsset;
@class TGMediaPickerAssetsGroup;

typedef enum {
    TGMediaPickerAssetAnyType,
    TGMediaPickerAssetPhotoType,
    TGMediaPickerAssetVideoType
} TGMediaPickerAssetType;

typedef enum {
    TGMediaPickerAuthorizationStatusNotDetermined,
    TGMediaPickerAuthorizationStatusRestricted,
    TGMediaPickerAuthorizationStatusDenied,
    TGMediaPickerAuthorizationStatusAuthorized
} TGMediaPickerAuthorizationStatus;

@interface TGMediaPickerAssetsLibrary : NSObject

@property (nonatomic, readonly) TGMediaPickerAssetType assetType;

@property (nonatomic, copy) void (^libraryChanged)(void);

- (instancetype)initForAssetType:(TGMediaPickerAssetType)assetType;

- (void)fetchGroupsWithCompletionBlock:(void(^)(NSArray *groups, TGMediaPickerAuthorizationStatus status, NSError *error))completionBlock;
- (void)fetchAssetsOfAssetsGroup:(TGMediaPickerAssetsGroup *)assetsGroup withCompletionBlock:(void (^)(NSArray *assets, TGMediaPickerAuthorizationStatus status, NSError *error))completionBlock;

- (void)saveAssetWithImage:(UIImage *)image completionBlock:(void(^)(bool success, NSError *error))completionBlock;
- (void)saveAssetWithImageData:(NSData *)data completionBlock:(void(^)(bool success, NSError *error))completionBlock;
- (void)saveAssetWithImageAtURL:(NSURL *)url completionBlock:(void(^)(bool success, NSError *error))completionBlock;
- (void)saveAssetWithVideoAtURL:(NSURL *)url completionBlock:(void(^)(bool success, NSError *error))completionBlock;

@end
