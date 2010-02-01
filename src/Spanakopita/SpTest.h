/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface SpTest : NSObject {
	WebView *webView;
	NSString *curPath;
}
@property(retain) IBOutlet WebView *webView;
@property(retain) NSString *curPath;

- (IBAction)load:(id)sender;
@end
