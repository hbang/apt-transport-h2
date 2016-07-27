#import "HBH2SessionDelegate.h"

@implementation HBH2SessionDelegate {
	H2Method *_h2Method;
}

- (instancetype)initWithH2Method:(H2Method *)h2Method {
	self = [self init];

	if (self) {
		_h2Method = h2Method;
	}

	return self;
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
	// tell apt
	_h2Method->RequestReceivedError(error);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler {
	// tell apt
	_h2Method->RequestWillRedirect(response.URL);

	// allow the redirect
	completionHandler(newRequest);
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytes {
	// tell apt
	_h2Method->RequestDidWriteData(totalBytesWritten, totalBytes);
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
	// tell the method to do its thing and tell apt
	_h2Method->RequestDidFinish(location);
}

@end
