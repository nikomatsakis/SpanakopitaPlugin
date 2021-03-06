/** See file LICENSE.txt for licensing information. **/

#import "SpPlugin.h"
#import "SpUrlProtocol.h"
#import <objc/runtime.h>

#define DEBUG 0

int SpPluginKey = 0;

@implementation SpPlugin
- (id)initWithPlugInController:(id <TMPlugInController>)aController
{
	if(self = [super init]) {
		[self installMenuItem];
		insertControllers = [[NSMutableArray alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowWillClose:) 
													 name:NSWindowWillCloseNotification 
												   object:nil];		
		
		[NSURLProtocol registerClass:[SpUrlProtocol class]];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	if(currentProjectWindow) {
		
		for(SpInsertController *contr in insertControllers)
			if(contr.projectWindow == currentProjectWindow)
				return; // already exists
		
		SpInsertController *contr = [[[SpInsertController alloc] initWithProjectWindow:currentProjectWindow] autorelease];
		contr.delegate = self;
		
		// Have to wrap the text editing area (an NSScrollView) with a Split view:
		NSArray *subviews = [[currentProjectWindow contentView] subviews];
		for(NSView *subview in subviews) {
			if([subview isKindOfClass:[NSScrollView class]]) { // Found it
				[contr wrap:subview];
				break;
			}
		}		
		
		[insertControllers addObject:contr];
	}
}

- (void)removeSpanakopita:(SpInsertController*)contr
{
	[contr unwrap];
	[insertControllers removeObject:contr];
}

- (void) windowWillClose:(NSNotification*)aNotification
{
	if(DEBUG) {
		NSWindow *window = [aNotification object];
		
		for(SpInsertController *contr in insertControllers)
			if(contr.projectWindow == window) {
				[self removeSpanakopita:contr];
				return; // already exists
			}
	}
}

- (void)unwrapRequested:(SpInsertController*)contr
{
	[self removeSpanakopita:contr];	
}

- (void)changeToPath:(NSString*)path
{
	NSURL *fileURL = [NSURL fileURLWithPath:path];
	NSString *textMateURL = [NSString stringWithFormat:@"txmt://open?url=%@", fileURL];
	NSURL *url = [NSURL URLWithString:textMateURL];
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	if(DEBUG)
		NSLog(@"textMateURL=%@", url);
	[workspace openURL:url];
}	

@end
