/** See file LICENSE.txt for licensing information. **/

#import "SpInsertController.h"
#import "SpUrlProtocol.h"
#import "TextMate.h"
#import <objc/runtime.h>

#define DEBUG 0

int SpWindowControllerContext;

@implementation SpInsertController

@synthesize projectWindow, currentFilePath, mainView, webView, delegate;

+ (id) wrapTextMateEditorInProjectWindow:(NSWindow *)aWindow
{
	SpInsertController *controller = objc_getAssociatedObject(aWindow, &SpWindowControllerContext);
	if(controller == nil) { // No associated object?
		controller = [[[SpInsertController alloc] initWithProjectWindow:aWindow] autorelease];
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
		
		if(DEBUG)
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
	if(DEBUG)
		NSLog(@"SpInsertController %p freed", self);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[projectWindow removeObserver:self forKeyPath:@"representedFilename"];
	self.projectWindow = nil;
	self.webView = nil;
	self.mainView = nil;
	[super dealloc];
}

- (void)setDelegate:(id<SpInsertControllerDelegate>)aDelegate
{
	delegate = aDelegate;
	if(DEBUG)
		NSLog(@"[%p setDelegate:%@]", self, delegate);
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
	if(![currentFilePath isEqual:path] && [path length] > 0 ) {
		self.currentFilePath = path;
		NSURL *url = [[[NSURL alloc] initWithScheme:SP_SCHEME /* Using this form handles any %20 escapes */
											  host:@""
											  path:path] autorelease];
		if(DEBUG)
			NSLog(@"currentFilePath: %@ url: %@", currentFilePath, url);
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
				if(DEBUG)
					NSLog(@"Redirectoring to %@ (delegate=%@)", path, delegate);
				[delegate changeToPath:path];
			}
		}
    }
}

@end
