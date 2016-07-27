@import Foundation;

#import "h2.h"

@interface HBH2SessionDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

- (instancetype)initWithH2Method:(H2Method *)h2Method;

@end
