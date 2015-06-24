#import "TGMediaPickerAssetsGroup.h"

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface TGMediaPickerAssetsGroup ()
{
    NSArray *_latestAssets;
    
    NSString *_persistentId;
    NSString *_title;
}
@end

@implementation TGMediaPickerAssetsGroup

- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)assetCollection fetchResult:(PHFetchResult *)fetchResult latestAssets:(NSArray *)latestAssets
{
    self = [super init];
    if (self != nil)
    {
        _backingAssetCollection = assetCollection;
        _backingFetchResult = fetchResult;
        _latestAssets = latestAssets;
        if (assetCollection.assetCollectionType == PHAssetCollectionTypeSmartAlbum &&
            assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary)
        {
            _isCameraRoll = true;
        }
    }
    return self;
}

- (instancetype)initWithPHFetchResult:(PHFetchResult *)fetchResult latestAssets:(NSArray *)latestAssets
{
    self = [super init];
    if (self != nil)
    {
        _backingFetchResult = fetchResult;
        _title = @"Camera Roll";
        _isCameraRoll = true;
        _latestAssets = latestAssets;
        _persistentId = @"camera_roll";
    }
    return self;
}

- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup latestAssets:(NSArray *)latestAssets
{
    self = [super init];
    if (self != nil)
    {
        _backingAssetsGroup = assetsGroup;
        _isCameraRoll = ([[assetsGroup valueForProperty:ALAssetsGroupPropertyType] integerValue] == ALAssetsGroupSavedPhotos);
        _latestAssets = latestAssets;
    }
    return self;
}

- (NSArray *)latestAssets
{
    return _latestAssets;
}

- (NSString *)persistentId
{
    if (_backingAssetCollection != nil)
        return _backingAssetCollection.localIdentifier;
    else if (_backingAssetsGroup != nil)
        return [_backingAssetsGroup valueForProperty:ALAssetsGroupPropertyPersistentID];
    
    return _persistentId;
}

- (NSString *)title
{
    if (_backingAssetCollection != nil)
        return _backingAssetCollection.localizedTitle;
    else if (_backingAssetsGroup != nil)
        return [self.backingAssetsGroup valueForProperty:ALAssetsGroupPropertyName];
        
    return _title;
}

- (NSUInteger)assetCount
{
    if (_backingFetchResult != nil)
         return _backingFetchResult.count;
    else if (_backingAssetsGroup != nil)
        return _backingAssetsGroup.numberOfAssets;
    
    return 0;
}

@end
