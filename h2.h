@import Foundation;

#include <iostream>
#include <apt-pkg/acquire-method.h>

using std::cout;
using std::endl;

class H2Method;

class H2Method : public pkgAcqMethod
{
	virtual bool Fetch(FetchItem *);
	void Configure();

	void HandleNSError(NSError *error);

	FetchResult Res;
	FetchItem Itm;
	NSURLSession *Session;

	bool GotFirstByte;

	public:

	void RequestReceivedError(NSError *error);
	void RequestWillRedirect(NSURL *toURL);
	void RequestDidWriteData(int64_t totalBytesWritten, int64_t totalBytes);
	void RequestDidFinish(NSURL *location);

	H2Method() : pkgAcqMethod("1.0", Pipeline | SendConfig)
	{
		Configure();
	};
};

URI Proxy;
