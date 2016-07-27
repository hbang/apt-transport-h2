@import Darwin;

#import "h2.h"
#include <apt-pkg/fileutl.h>
#include <apt-pkg/error.h>
#include <apt-pkg/hashes.h>
#include <apt-pkg/netrc.h>
#include <apt-pkg/configuration.h>
#import <MobileGestalt/MobileGestalt.h>

@interface HBH2SessionDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

- (instancetype)initWithH2Method:(H2Method *)h2Method;

@end

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

using namespace std;

void H2Method::Configure() {
	// build our global config
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];

	// grab the machine name
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *machine = (char *)malloc(size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);

	// set the extra headers to send with requests
	configuration.HTTPAdditionalHeaders = @{
		@"User-Agent": @(_config->Find("Acquire::http::User-Agent", "Telesphoreo APT-HTTP/1.0.592 (h2/1.0)").c_str()),
		@"X-Firmware": [NSProcessInfo processInfo].operatingSystemVersionString,
		@"X-Machine": @(machine),
		@"X-Unique-ID": (__bridge NSString *)MGCopyAnswer(CFSTR("UniqueDeviceID"))
	};

	// set the timeout interval as per the config
	configuration.timeoutIntervalForRequest = _config->FindI("Acquire::h2::Timeout", _config->FindI("Acquire::http::Timeout", 120));

	// might as well require at least the latest-ish version of TLS
	configuration.TLSMinimumSupportedProtocol = kTLSProtocol12;

	// if caching has been turned off, ensure we ignore the cache
	if (_config->FindB("Acquire::h2::No-Cache", _config->FindB("Acquire::http::No-Cache", false))) {
		configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	}

	// use our config to make an NSURLSession for ourselves
	Session = [NSURLSession sessionWithConfiguration:configuration delegate:[[HBH2SessionDelegate alloc] initWithH2Method:this] delegateQueue:nil];
}


bool H2Method::Fetch(FetchItem *Itm) {
	// bool verbose = _config->FindB("Debug::Acquire::h2", false);

	NSURL *url = [NSURL URLWithString:@(Itm->Uri.c_str())];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

	NSURLSessionDownloadTask *task = [Session downloadTaskWithRequest:request];
	[task resume];

	return true;
}

void H2Method::HandleNSError(NSError *error) {
	NSString *message = [NSString stringWithFormat:@"%@ (%@ %li)", error.localizedDescription, error.domain, (long)error.code];
	Fail(string(message.UTF8String));
}

void H2Method::RequestReceivedError(NSError *error) {
	HandleNSError(error);
}

void H2Method::RequestWillRedirect(NSURL *toURL) {
	Redirect(string(toURL.absoluteString.UTF8String));
}

void H2Method::RequestDidWriteData(int64_t totalBytesWritten, int64_t totalBytes) {
	Res.Size = (unsigned long)totalBytes;

	if (!GotFirstByte) {
		GotFirstByte = true;
		URIStart(Res);
	}
}

void H2Method::RequestDidFinish(NSURL *location) {
	NSError *error = nil;
	[[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:@(Queue->DestFile.c_str())] error:&error];

	if (error) {
		HandleNSError(error);
	} else {
		URIDone(Res);
	}
}
