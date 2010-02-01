/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>
#import "SpInsertController.h"
#import "TextMate.h"

@interface SpPlugin : NSObject {
	NSMutableArray *spInsertControllers;
	NSMenu* windowMenu;
	NSMenuItem* showClockMenuItem;
}

- (void)installMenuItem;
- (void)uninstallMenuItem;
- (void)disposeWindows;

@end
