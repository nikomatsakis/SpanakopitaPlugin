/** See file LICENSE.txt for licensing information. **/

#import "SpInsertController.h"
#import "SpUrlProtocol.h"
#import "TextMate.h"
#import <objc/runtime.h>
#import <CoreServices/CoreServices.h>

#define DEBUG 0

int SpWindowControllerContext;

@interface SpInsertController()
@property(retain) NSView *wrappedView;
- (void)deallocateEventStream;
@end

@implementation SpInsertController

@synthesize projectWindow, currentFilePath, mainView, webView, delegate, wrappedView;

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
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowWillClose:) 
													 name:NSWindowWillCloseNotification 
												   object:projectWindow];
	}
	return self;
}

- (void)dealloc
{
	NSAssert(wrappedView == nil, @"Still wrapped when dealloc'd");
	
	if(DEBUG)
		NSLog(@"SpInsertController %p freed", self);
	[self deallocateEventStream];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[projectWindow removeObserver:self forKeyPath:@"representedFilename"];
	self.projectWindow = nil;
	[webView setFrameLoadDelegate:nil];
	self.webView = nil;
	self.mainView = nil;
	[super dealloc];
}

- (void) windowWillClose:(NSNotification*)aNotification
{
	if(DEBUG)
		NSLog(@"InsertController: windowWillClose rc=%d (window rc=%d)", 
			  [self retainCount], [projectWindow retainCount]);
}

static void SpInsertControllerCallback(ConstFSEventStreamRef streamRef,
									   void *clientCallBackInfo,
									   size_t numEvents,
									   void *eventPaths,
									   const FSEventStreamEventFlags eventFlags[],
									   const FSEventStreamEventId eventIds[])
{
	SpInsertController *self = (SpInsertController*)clientCallBackInfo;
	[self reload:self];
}

- (void)allocateEventStreamForPath:(NSString*)directoryPath
{
	[self deallocateEventStream];
	
	FSEventStreamContext context = {
		.version = 0,
		.info = self,
		.retain = NULL,
		.release = NULL,
		.copyDescription = NULL
	};
	
	eventStream = FSEventStreamCreate(kCFAllocatorDefault, 
									  SpInsertControllerCallback, 
									  &context, 
									  (CFArrayRef)[NSArray arrayWithObject:directoryPath], 
									  kFSEventStreamEventIdSinceNow, 
									  0.2, // seconds to wait
									  0);
	FSEventStreamScheduleWithRunLoop(eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	FSEventStreamStart(eventStream);
}

- (void)deallocateEventStream
{
	if(eventStream) {
		FSEventStreamStop(eventStream);
		FSEventStreamInvalidate(eventStream);
		FSEventStreamRelease(eventStream);
		eventStream = NULL;
	}
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
	
	self.wrappedView = subview;
	
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

- (void) unwrap
{
	if(wrappedView) {
		id splitView = [wrappedView superview];
		id superview = [splitView superview];
		[wrappedView removeFromSuperview];
		[superview replaceSubview:splitView with:wrappedView];
		self.wrappedView = nil;
	}
}

- (void)changeCurrentFilePath:(NSString*)path
{
	self.currentFilePath = path;
	[self allocateEventStreamForPath:[path stringByDeletingLastPathComponent]];
}

- (void)reloadCurrentFilePath
{
	NSString *path = [[self.projectWindow representedFilename] stringByStandardizingPath];
	if(![currentFilePath isEqual:path] && [path length] > 0 ) {
		[self changeCurrentFilePath:path];
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

- (void) remove:(id)sender
{
	[delegate unwrapRequested:self];
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
				[self changeCurrentFilePath:path];
				if(DEBUG)
					NSLog(@"Redirectoring to %@ (delegate=%@)", path, delegate);
				[delegate changeToPath:path];
			}
		}
    }
}

@end
