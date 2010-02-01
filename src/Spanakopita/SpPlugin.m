/** See file LICENSE.txt for licensing information. **/

#import "SpPlugin.h"
#import "SpUrlProtocol.h"
#import <objc/runtime.h>

int SpPluginKey = 0;

@implementation SpPlugin
- (id)initWithPlugInController:(id <TMPlugInController>)aController
{
	if(self = [super init]) {
		[self installMenuItem];
		
		[NSURLProtocol registerClass:[SpUrlProtocol class]];
	}
	return self;
}

- (void)dealloc
{
	[self uninstallMenuItem];
	[super dealloc];
}

- (NSWindow*)currentProjectWindow
{
	for (NSWindow *w in [[NSApplication sharedApplication] orderedWindows]) {
		if ([[[w windowController] className] isEqualToString: @"OakProjectController"] &&
			[[w windowController] projectDirectory]) {
			return w;
		}
	}	
	return nil;	
}

- (void)installMenuItem
{
	if(windowMenu = [[[[NSApp mainMenu] itemWithTitle:@"Window"] submenu] retain])
	{
		unsigned index = 0;
		NSArray* items = [windowMenu itemArray];
		for(int separators = 0; index != [items count] && separators != 2; index++)
			separators += [[items objectAtIndex:index] isSeparatorItem] ? 1 : 0;
		
		showClockMenuItem = [[NSMenuItem alloc] initWithTitle:@"Spanakopify Project" 
													   action:@selector(showSpanakopita:) 
												keyEquivalent:@""];
		[showClockMenuItem setTarget:self];
		[windowMenu insertItem:showClockMenuItem atIndex:index ? index-1 : 0];
	}
}

- (void)uninstallMenuItem
{
	[windowMenu removeItem:showClockMenuItem];
	
	[showClockMenuItem release];
	showClockMenuItem = nil;
	
	[windowMenu release];
	windowMenu = nil;
}

- (void)showSpanakopita:(id)sender
{
	NSWindow *currentProjectWindow = [self currentProjectWindow];
	if(currentProjectWindow) 
		[SpInsertController insertIntoProjectWindow:currentProjectWindow];
}

@end
