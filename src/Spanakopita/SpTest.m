/** See file LICENSE.txt for licensing information. **/

#import "SpTest.h"
#import "SpUrlProtocol.h"

@implementation SpTest

@synthesize webView, curPath;

- (void) awakeFromNib
{
	[NSURLProtocol registerClass:[SpUrlProtocol class]];
}

- (void) dealloc
{
	self.webView = nil;
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
		self.curPath = [@"sp://" stringByAppendingString:path];
		NSURL *spUrl = [NSURL URLWithString:curPath];
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:spUrl]];
	}
}

@end
