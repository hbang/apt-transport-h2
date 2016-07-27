#import "h2.h"

int main(int argc, char *argv[]) {
	@autoreleasepool {
		// reset the locale. do we actually need this?
		setlocale(LC_ALL, "");

		// run!
		H2Method Mth;
		int result = Mth.Run();

		// start the run loop
		[[NSRunLoop mainRunLoop] run];

		// exit with the result as the exit code
		return result;
	}
}
