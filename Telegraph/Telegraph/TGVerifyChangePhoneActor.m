#import "TGVerifyChangePhoneActor.h"

#import "ActionStage.h"
#import "TGTelegraph.h"
#import "TGTelegramNetworking.h"

#import <MTProtoKit/MTRequest.h>

#import "TL/TLMetaScheme.h"

#import "TGSendCodeRequestBuilder.h"

@implementation TGVerifyChangePhoneActor

+ (void)load
{
    [ASActor registerActorClass:self];
}

+ (NSString *)genericPath
{
    return @"/verifyChangePhoneNumber/@";
}

- (NSString *)extractErrorType:(TLError *)error
{
    if ([error isKindOfClass:[TLError$richError class]])
    {
        if (((TLError$richError *)error).type.length != 0)
            return ((TLError$richError *)error).type;
        
        NSString *errorDescription = nil;
        if ([error isKindOfClass:[TLError$error class]])
            errorDescription = ((TLError$error *)error).text;
        else if ([error isKindOfClass:[TLError$richError class]])
            errorDescription = ((TLError$richError *)error).n_description;
        
        NSMutableString *errorString = [[NSMutableString alloc] init];
        for (int i = 0; i < (int)errorDescription.length; i++)
        {
            unichar c = [errorDescription characterAtIndex:i];
            if (c == ':')
                break;
            
            [errorString appendString:[[NSString alloc] initWithCharacters:&c length:1]];
        }
        
        if (errorString.length != 0)
            return errorString;
    }
    
    return nil;
}

- (void)execute:(NSDictionary *)options
{
    MTRequest *request = [[MTRequest alloc] init];
    
    if ([options[@"requestCall"] boolValue])
    {
        TLRPCauth_sendCall$auth_sendCall *sendCall = [[TLRPCauth_sendCall$auth_sendCall alloc] init];
        sendCall.phone_number = options[@"phoneNumber"];
        sendCall.phone_code_hash = options[@"phoneCodeHash"];
        request.body = sendCall;
    }
    else
    {
        TLRPCaccount_sendChangePhoneCode$account_sendChangePhoneCode *sendChangePhoneCode = [[TLRPCaccount_sendChangePhoneCode$account_sendChangePhoneCode alloc] init];
        sendChangePhoneCode.phone_number = options[@"phoneNumber"];
        request.body = sendChangePhoneCode;
    }
    
    __weak TGVerifyChangePhoneActor *weakSelf = self;
    [request setCompleted:^(id result, __unused NSTimeInterval timestamp, TLError *error)
    {
        [ActionStageInstance() dispatchOnStageQueue:^
        {
            __strong TGVerifyChangePhoneActor *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                if (error == nil)
                {
                    if ([options[@"requestCall"] boolValue])
                        [strongSelf sendCallCompleted];
                    else
                        [strongSelf sendRequestCompleted:result];
                }
                else
                {
                    [strongSelf sendRequestFailed:[self extractErrorType:error]];
                }
            }
        }];
    }];
    
    self.cancelToken = request.internalId;
    
    [[TGTelegramNetworking instance] addRequest:request];
}

- (void)sendCallCompleted
{
    [ActionStageInstance() actionCompleted:self.path result:nil];
}

- (void)sendRequestCompleted:(TLaccount_SentChangePhoneCode *)sentCode
{
    [ActionStageInstance() actionCompleted:self.path result:@{@"phoneCodeHash": sentCode.phone_code_hash, @"callTimeout": @(sentCode.send_call_timeout)}];
}

- (void)sendRequestFailed:(NSString *)errorText
{
    TGSendCodeError errorCode = TGSendCodeErrorUnknown;
    
    if ([errorText isEqualToString:@"PHONE_NUMBER_INVALID"])
        errorCode = TGSendCodeErrorInvalidPhone;
    else if ([errorText hasPrefix:@"FLOOD_WAIT"])
        errorCode = TGSendCodeErrorFloodWait;
    
    [ActionStageInstance() actionFailed:self.path reason:errorCode];
}

@end
