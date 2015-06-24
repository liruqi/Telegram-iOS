#import "TGInlineStickerSearchActor.h"

#import "TGTelegramNetworking.h"
#import "ActionStage.h"
#import "TGDatabase.h"

#import "TL/TLMetaScheme.h"

#import "TGDocumentMediaAttachment+Telegraph.h"

#import <MtProtoKit/MTProtoKit.h>

#import "TGStringUtils.h"

#import "TGStickerQueryCachedData.h"

@interface TGInlineStickerSearchActor ()
{
    NSString *_cachedFilePath;
    TGStickerQueryCachedData *_cachedData;
}

@end

@implementation TGInlineStickerSearchActor

+ (void)load
{
    [ASActor registerActorClass:self];
}

+ (NSString *)genericPath
{
    return @"/inlineStickerSearch/@";
}

- (void)execute:(NSDictionary *)options
{
    MTRequest *request = [[MTRequest alloc] init];
    
    NSString *cachedFilesDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"sticker-cache"];
    [[NSFileManager defaultManager] createDirectoryAtPath:cachedFilesDirectory withIntermediateDirectories:true attributes:nil error:nil];
    _cachedFilePath = [cachedFilesDirectory stringByAppendingPathComponent:[[(NSString *)options[@"query"] dataUsingEncoding:NSUTF8StringEncoding] stringByEncodingInHex]];
    
    TLRPCmessages_getStickers$messages_getStickers *getStickers = [[TLRPCmessages_getStickers$messages_getStickers alloc] init];
    getStickers.emoticon = options[@"query"];
    NSData *data = [NSData dataWithContentsOfFile:_cachedFilePath];
    if (data != nil)
    {
        _cachedData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_cachedData != nil)
        {
            getStickers.n_hash = _cachedData.queryHash;
            [ActionStageInstance() dispatchMessageToWatchers:self.path messageType:@"cachedDocuments" message:_cachedData.documents];
        }
        else
            getStickers.n_hash = @"";
        
    }
    else
        getStickers.n_hash = @"";
    
    request.body = getStickers;
    
    __weak TGInlineStickerSearchActor *weakSelf = self;
    [request setCompleted:^(TLmessages_Stickers *result, __unused NSTimeInterval timestamp, id error)
    {
        __strong TGInlineStickerSearchActor *strongSelf = weakSelf;
        if (error == nil)
            [strongSelf requestSuccess:result];
        else
            [strongSelf requestFailed];
    }];
    
    self.cancelToken = request.internalId;
    [[TGTelegramNetworking instance] addRequest:request];
}

- (void)requestSuccess:(TLmessages_Stickers *)stickers
{
    if ([stickers isKindOfClass:[TLmessages_Stickers$messages_stickersNotModified class]])
    {
        [ActionStageInstance() actionCompleted:self.path result:@{@"keepCache": @true, @"documents": _cachedData.documents}];
    }
    else if ([stickers isKindOfClass:[TLmessages_Stickers$messages_stickers class]])
    {
        NSMutableArray *documents = [[NSMutableArray alloc] init];
        
        for (TLDocument *documentDesc in ((TLmessages_Stickers$messages_stickers *)stickers).stickers)
        {
            TGDocumentMediaAttachment *document = [[TGDocumentMediaAttachment alloc] initWithTelegraphDocumentDesc:documentDesc];
            if (document != nil)
                [documents addObject:document];
        }
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[[TGStickerQueryCachedData alloc] initWithQueryHash:((TLmessages_Stickers$messages_stickers *)stickers).n_hash documents:documents]];
        [data writeToFile:_cachedFilePath atomically:true];
        
        [ActionStageInstance() actionCompleted:self.path result:@{@"documents": documents}];
    }
}

- (void)requestFailed
{
    [ActionStageInstance() actionFailed:self.path reason:-1];
}

@end
