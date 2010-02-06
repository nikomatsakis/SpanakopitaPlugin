/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>
#import "SpInsertController.h"
#import "TextMate.h"

@interface SpPlugin : NSObject <SpInsertControllerDelegate> {
	NSMenu* windowMenu;
	NSMenuItem* showClockMenuItem;
	NSMutableArray *insertControllers;
}

- (void)installMenuItem;
- (void)uninstallMenuItem;
- (void)changeToPath:(NSString *)path;
- (void)unwrapRequested:(SpInsertController*)contr;

@end
