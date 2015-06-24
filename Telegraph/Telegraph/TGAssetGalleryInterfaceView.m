#import "TGAssetGalleryInterfaceView.h"

#import "TGModernButton.h"
#import "TGFont.h"
#import "TGImageUtils.h"
#import "TGImagePickerCheckButton.h"

@interface TGAssetGalleryInterfaceView ()
{
    void (^_closePressed)();
    
    UIView *_toolbarView;
    TGModernButton *_cancelButton;
    TGModernButton *_doneButton;
    UIImageView *_countBadge;
    UILabel *_countLabel;
    TGImagePickerCheckButton *_checkButton;
    id<TGModernGalleryItem> _currentItem;
}

@end

@implementation TGAssetGalleryInterfaceView

@end
