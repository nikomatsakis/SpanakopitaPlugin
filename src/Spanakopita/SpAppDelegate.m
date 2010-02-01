/** See file LICENSE.txt for licensing information. **/

#import "SpAppDelegate.h"
#import "SpWindowController.h"

@implementation SpAppDelegate

- (void) openDocument:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:YES];
	[panel setCanCreateDirectories:YES];
	[panel setAllowsMultipleSelection:NO];	
	NSInteger res = [panel runModal];
	if(res == NSFileHandlingPanelOKButton) {
		NSURL *url = [[panel URLs] objectAtIndex:0];
		NSString *path = [url path];
		
		SpWindowController *wc = [[SpWindowController alloc] initWithPath:path];
		[wc showWindow:self];
		// XXX memory management
	}
	
}

@end
