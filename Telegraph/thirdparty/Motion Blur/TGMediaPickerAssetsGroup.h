#import <Foundation/Foundation.h>

@class PHAssetCollection;
@class PHFetchResult;
@class ALAssetsGroup;

@interface TGMediaPickerAssetsGroup : NSObject

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *persistentId;
@property (nonatomic, readonly) NSUInteger assetCount;
@property (nonatomic, readonly) NSArray *latestAssets;
@property (nonatomic, readonly) BOOL isCameraRoll;

@property (nonatomic, readonly) PHAssetCollection *backingAssetCollection;
@property (nonatomic, readonly) PHFetchResult *backingFetchResult;
@property (nonatomic, readonly) ALAssetsGroup *backingAssetsGroup;

- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)assetCollection fetchResult:(PHFetchResult *)fetchResult latestAssets:(NSArray *)latestAssets;
- (instancetype)initWithPHFetchResult:(PHFetchResult *)fetchResult latestAssets:(NSArray *)latestAssets;
- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup latestAssets:(NSArray *)latestAssets;

@end
