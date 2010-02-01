/** See file LICENSE.txt for licensing information. **/

#import "SpTest.h"
#import "SpUrlProtocol.h"
#import "SpInsertController.h"

@implementation SpTest

@synthesize window, curPath;

- (void) awakeFromNib
{
	[NSURLProtocol registerClass:[SpUrlProtocol class]];
	
	[SpInsertController wrapTextMateEditorInProjectWindow:window];
}

- (void) dealloc
{
	self.window = nil;
	[super dealloc];
}

- (IBAction) load:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanCreateDirectories:YES];
	[panel setAllowsMultipleSelection:NO];	
	NSInteger res = [panel runModal];
	if(res == NSFileHandlingPanelOKButton) {
		NSURL *url = [[panel URLs] objectAtIndex:0];
		NSString *path = [url path];
		[window setRepresentedFilename:path];
	}
}

@end
