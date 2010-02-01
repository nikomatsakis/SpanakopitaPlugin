/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>

#define SP_SCHEME @"sp"
#define DEFAULTS_PREFIX @"com.smallcultfollowing.Spanakopita:"

@interface SpUrlProtocol : NSURLProtocol {
	BOOL stop;
}

@end
