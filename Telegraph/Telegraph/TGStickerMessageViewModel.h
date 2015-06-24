#import "TGMessageViewModel.h"

@class TGMessage;
@class TGDocumentMediaAttachment;

@interface TGStickerMessageViewModel : TGMessageViewModel

- (instancetype)initWithMessage:(TGMessage *)message document:(TGDocumentMediaAttachment *)document size:(CGSize)size author:(TGUser *)author context:(TGModernViewContext *)context;

@end
