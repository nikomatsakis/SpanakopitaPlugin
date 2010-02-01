/** See file LICENSE.txt for licensing information. **/

#import "SpInsertController.h"
#import "SpUrlProtocol.h"
#import "TextMate.h"
#import <objc/runtime.h>

int SpWindowControllerContext;

@implementation SpInsertController

@synthesize projectWindow, currentFilePath, mainView, webView, delegate;

+ (id) wrapTextMateEditorInProjectWindow:(NSWindow *)aWindow
{
	id controller = objc_getAssociatedObject(aWindow, &SpWindowControllerContext);
	if(controller == nil) { // No associated object?
		SpInsertController *controller = [[[SpInsertController alloc] initWithProjectWindow:aWindow] autorelease];
		objc_setAssociatedObject(aWindow, &SpWindowControllerContext, controller, OBJC_ASSOCIATION_RETAIN);
		
		// Have to wrap the text editing area (an NSScrollView) with a Split view:
		NSArray *subviews = [[aWindow contentView] subviews];
		for(NSView *subview in subviews) {
			if([subview isKindOfClass:[NSScrollView class]]) { // Found it
				[controller wrap:subview];
				break;
			}
		}		
	}
	return controller;
}

- initWithProjectWindow:(NSWindow*)aWindow
{
	if((self = [super init])) {
		self.projectWindow = aWindow;
		
		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSNib *nib = [[NSNib alloc] initWithNibNamed:@"SpanakopitaInsert" bundle:bundle];
		if(![nib instantiateNibWithOwner:self topLevelObjects:nil])
			NSLog(@"Failed to init nib");
		
		NSLog(@"SpInsertController %p allocated", self);
		[webView setShouldCloseWithWindow:YES];
		[webView setFrameLoadDelegate:self];
		
		[self reloadCurrentFilePath];		
		[projectWindow addObserver:self forKeyPath:@"representedFilename" options:0 context:&SpWindowControllerContext];
	}
	return self;
}

- (void)dealloc
{
	NSLog(@"SpInsertController %p freed", self);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[projectWindow removeObserver:self forKeyPath:@"representedFilename"];
	self.projectWindow = nil;
	self.webView = nil;
	self.mainView = nil;
	[super dealloc];
}

- (void) wrap:(NSView *)subview 
{
	NSView *superview = [subview superview];
	
	// Create splitView that will encompass scroll view:
	NSSplitView *splitView = [[[NSSplitView alloc] initWithFrame:[subview frame]] autorelease];
	[splitView setVertical:NO];
	[splitView setAutoresizingMask:[subview autoresizingMask]];
	
	// Substitute and connect the various views:
	[subview retain];
	[superview replaceSubview:subview with:splitView];				
	[splitView addSubview:subview];
	[splitView addSubview:mainView];		
	[subview release];
}

- (void)reloadCurrentFilePath
{
	NSString *path = [[self.projectWindow representedFilename] stringByStandardizingPath];
	if(![currentFilePath isEqual:path]) {
		self.currentFilePath = path;
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", SP_SCHEME, currentFilePath]];
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &SpWindowControllerContext) {
		[self reloadCurrentFilePath];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void) reload:(id)sender
{
	[[webView mainFrame] reloadFromOrigin];
}

#pragma mark WebFrameLoadDelegate Informal Protocol

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]) {
        NSURL *url = [[[frame provisionalDataSource] request] URL];
		if([[url scheme] isEqual:SP_SCHEME] || [url isFileURL]) {
			NSString *path = [[url path] stringByStandardizingPath];
			if(path && ![self.currentFilePath isEqual:path]) {				
				self.currentFilePath = path;
				[delegate changeToPath:path];
			}
		}
    }
}

@end
