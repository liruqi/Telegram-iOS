#import <Foundation/Foundation.h>

@class PHAsset;
@class ALAsset;

@interface TGMediaPickerAsset : NSObject

@property (nonatomic, readonly) NSString *persistentId;
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) CGSize dimensions;
@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) bool isVideo;
@property (nonatomic, readonly) NSTimeInterval videoDuration;

@property (nonatomic, readonly) PHAsset *backingAsset;
@property (nonatomic, readonly) ALAsset *backingLegacyAsset;

- (instancetype)initWithPHAsset:(PHAsset *)asset;
- (instancetype)initWithALAsset:(ALAsset *)asset;

- (NSString *)uniqueId;

@end
