#import "RNFileAccess.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import <React/RCTConvert.h>
#import <React/RCTBridge.h>
#import <React/RCTUtils.h>


static NSString *const E_DOCUMENT_PICKER_CANCELED = @"DOCUMENT_PICKER_CANCELED";
static NSString *const E_INVALID_DATA_RETURNED = @"INVALID_DATA_RETURNED";

static NSString *const OPTION_TYPE = @"type";
static NSString *const OPTION_MULTIPLE = @"multiple";

static NSString *const FIELD_URI = @"uri";
static NSString *const FIELD_FILE_COPY_URI = @"fileCopyUri";
static NSString *const FIELD_COPY_ERR = @"copyError";
static NSString *const FIELD_NAME = @"name";
static NSString *const FIELD_TYPE = @"type";
static NSString *const FIELD_SIZE = @"size";


@implementation RNFileAccess {
//    UIDocumentPickerMode mode;
//    NSString *copyDestination;
//    NSMutableArray *composeResolvers;
//    NSMutableArray *composeRejecters;
    NSMutableArray *urls;
}


- (instancetype)init
{
    if ((self = [super init])) {
//        composeResolvers = [NSMutableArray new];
//        composeRejecters = [NSMutableArray new];
        urls = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"Clear All File Access!!!\n");
    for (NSURL *url in urls) {
        [url stopAccessingSecurityScopedResource];
    }
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}


RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(stopAccess:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *urlString = options[@"url"];
    
    NSLog(@"stopAccess url = %@", urlString);
    
//    NSMutableArray *discardedItems = [NSMutableArray array];
    for (NSURL *url in urls) {
        if ([url.absoluteString isEqual:urlString]) {
            [url stopAccessingSecurityScopedResource];
//            [discardedItems addObject:url];
            resolve(@"success");
            return;
        }
    }
    
//    [urls removeObjectsInArray:discardedItems];
    
//    NSLog(@"urls length = %d", [urls count]);
    
//    if([discardedItems count] == 0) {
//        resolve(@"failed");
//    } else {
//        resolve(@"success");
//    }
    
    resolve(@"failed");

}


- (NSData *)dataFromHexString:(NSString *)hexString{
    const char *chars = [hexString UTF8String];
    int i = 0;
    int len = (int)hexString.length;
    NSMutableData *data = [NSMutableData dataWithCapacity:len/2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i<len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    return data;
}






RCT_EXPORT_METHOD(startAccess:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    NSString *urlString = options[@"url"];
    
    NSLog(@"startAccess url = %@", urlString);

    // try to find an exist URL
    for (NSURL *url in urls) {
        if ([url.absoluteString isEqual:urlString]) {
            // found
            NSLog(@"[FileAccess] found URL\n");
            [url startAccessingSecurityScopedResource];
            resolve(@"success");
            return;
        }
    }
    
    // try to use bookmark data string
    NSString* dataString = options[@"bookmark"];
    if(!dataString) {
        NSLog(@"[FileAccess] no bookmark data: %@\n", dataString);
        resolve(@"failed");
        return;
    }
    
    NSLog(@"[FileAccess] parse bookmark data\n");
    
    @try {
        
//        NSLog(@"bookmark string length = %lu\n", [dataString length]);
        
//          NSData* bookmark = [[NSData alloc] initWithBase64EncodedString:dataString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSData* bookmark = [self dataFromHexString:dataString];
        
        NSLog(@"bookmark data length = %lu\n", [bookmark length]);
        
        BOOL bookmarkIsStale = NO;
          NSError* theError = nil;
          NSURL* bookmarkURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                  options:NSURLBookmarkResolutionWithoutUI
                                                  relativeToURL:nil
                                                  bookmarkDataIsStale:&bookmarkIsStale
                                                  error:&theError];
          
        
        if(!bookmarkURL) {
            NSLog(@"error=%@", theError);
            reject(E_DOCUMENT_PICKER_CANCELED, @"bookmark url is nil", nil);
            return;
        }
        
          [bookmarkURL startAccessingSecurityScopedResource];
          
          
          // save the new bookmark URL
          [urls addObject:bookmarkURL];
          
          NSLog(@"[FileAccess] add bookmark data, urls length=%d\n", [urls count]);
        
        
          
      //    resole(true);
          resolve(@"success");
          
    }
    @catch (NSException *e) {    //捕获一个比较重要的异常类型。
        NSLog(@"%@", e);
        reject(E_DOCUMENT_PICKER_CANCELED, @"bookmark data invalid", nil);
    }
    @finally {        //不管有没有异常finally内的代码都会执行。
    }
 
    
//    reject(E_DOCUMENT_PICKER_CANCELED, @"User canceled document picker", nil);
}

@end
