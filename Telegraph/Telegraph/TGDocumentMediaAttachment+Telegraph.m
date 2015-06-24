/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGDocumentMediaAttachment+Telegraph.h"

#import "TGImageInfo+Telegraph.h"

@implementation TGDocumentMediaAttachment (Telegraph)

- (instancetype)initWithTelegraphDocumentDesc:(TLDocument *)desc
{
    self = [super init];
    if (self != nil)
    {
        self.type = TGDocumentMediaAttachmentType;
        
        self.documentId = desc.n_id;
        
        if ([desc isKindOfClass:[TLDocument$document class]])
        {
            TLDocument$document *concreteDocument = (TLDocument$document *)desc;
            
            self.accessHash = concreteDocument.access_hash;
            self.datacenterId = concreteDocument.dc_id;
            self.date = concreteDocument.date;
            
            NSMutableArray *attributes = [[NSMutableArray alloc] init];
            for (id attribute in concreteDocument.attributes)
            {
                if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeFilename class]])
                {
                    TLDocumentAttribute$documentAttributeFilename *concreteAttribute = attribute;
                    [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:concreteAttribute.file_name]];
                }
                else if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeAnimated class]])
                {
                    [attributes addObject:[[TGDocumentAttributeAnimated alloc] init]];
                }
                else if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeAudio class]])
                {
                    TLDocumentAttribute$documentAttributeAudio *concreteAttrbute = attribute;
                }
                else if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeImageSize class]])
                {
                    TLDocumentAttribute$documentAttributeImageSize *concreteAttribute = attribute;
                    [attributes addObject:[[TGDocumentAttributeImageSize alloc] initWithSize:CGSizeMake(concreteAttribute.w, concreteAttribute.h)]];
                }
                else if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeSticker class]])
                {
                    [attributes addObject:[[TGDocumentAttributeSticker alloc] init]];
                }
                else if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeVideo class]])
                {
                    TLDocumentAttribute$documentAttributeVideo *concreteAttribute = attribute;
                }
            }
            self.attributes = attributes;
            self.mimeType = concreteDocument.mime_type;
            self.size = concreteDocument.size;
            
            NSData *cachedData = nil;
            TGImageInfo *thumbmailInfo = concreteDocument.thumb == nil ? nil : [[TGImageInfo alloc] initWithTelegraphSizesDescription:@[concreteDocument.thumb] cachedData:&cachedData];
            if (thumbmailInfo != nil && !thumbmailInfo.empty)
            {
                self.thumbnailInfo = thumbmailInfo;
                if (cachedData != nil)
                {
                    static NSString *filesDirectory = nil;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^
                    {
                        filesDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0] stringByAppendingPathComponent:@"files"];
                    });
                    
                    NSString *fileDirectoryName = nil;
                    fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", self.documentId];
                    NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
                    
                    [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
                    
                    NSString *filePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
                    
                    [cachedData writeToFile:filePath atomically:true];
                }
            }
        }
    }
    return self;
}

@end
