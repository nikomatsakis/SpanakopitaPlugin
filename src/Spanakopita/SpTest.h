/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface SpTest : NSObject {
	NSWindow *window;
	NSString *curPath;
}
@property(retain) IBOutlet NSWindow *window;
@property(retain) NSString *curPath;

- (IBAction)load:(id)sender;
@end
