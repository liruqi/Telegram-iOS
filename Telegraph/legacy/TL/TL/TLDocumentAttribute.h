#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLDocumentAttribute : NSObject <TLObject>


@end

@interface TLDocumentAttribute$documentAttributeImageSize : TLDocumentAttribute

@property (nonatomic) int32_t w;
@property (nonatomic) int32_t h;

@end

@interface TLDocumentAttribute$documentAttributeAnimated : TLDocumentAttribute


@end

@interface TLDocumentAttribute$documentAttributeSticker : TLDocumentAttribute


@end

@interface TLDocumentAttribute$documentAttributeVideo : TLDocumentAttribute

@property (nonatomic) int32_t duration;
@property (nonatomic) int32_t w;
@property (nonatomic) int32_t h;

@end

@interface TLDocumentAttribute$documentAttributeAudio : TLDocumentAttribute

@property (nonatomic) int32_t duration;

@end

@interface TLDocumentAttribute$documentAttributeFilename : TLDocumentAttribute

@property (nonatomic, retain) NSString *file_name;

@end

