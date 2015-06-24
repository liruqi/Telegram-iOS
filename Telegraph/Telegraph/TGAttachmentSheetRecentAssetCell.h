#import <UIKit/UIKit.h>

@class TGMediaPickerAsset;

@interface TGAttachmentSheetRecentAssetCell : UICollectionViewCell

- (void)setAsset:(TGMediaPickerAsset *)asset isAssetSelected:(bool (^)(TGMediaPickerAsset *))isAssetSelected isAssetHidden:(bool (^)(TGMediaPickerAsset *))isAssetHidden changeAssetSelection:(void (^)(TGMediaPickerAsset *))changeAssetSelection openAsset:(void (^)(TGMediaPickerAsset *))openAsset;
- (UIView *)referenceViewForAsset:(TGMediaPickerAsset *)asset;
- (void)updateSelection;
- (void)updateHidden:(bool)animated;

@end
