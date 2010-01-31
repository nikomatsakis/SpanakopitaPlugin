//
//  SpWindowController.m
//  Spanakopita
//
//  Created by Niko Matsakis on 1/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SpInsertController.h"
#import "SpUrlProtocol.h"
#import "TextMate.h"

int SpWindowControllerContext;

@implementation SpInsertController

@synthesize project, projectWindow, currentFilePath, webView;

- initWithProjectController:(OakProjectController*)aProject
			  projectWindow:(NSWindow*)aWindow
{
	if((self = [super init])) {
		self.project = aProject;
		self.projectWindow = aWindow;
		
		// Have to wrap the text editing area (an NSScrollView) with a Split view:
		NSView *contentView = [projectWindow contentView];
		NSArray *subviews = [contentView subviews];
		for(NSView *subview in subviews) {
			if([subview isKindOfClass:[NSScrollView class]]) { // Found it
				// Create splitView that will encompass scroll view:
				NSSplitView *splitView = [[[NSSplitView alloc] initWithFrame:[subview frame]] autorelease];
				[splitView setVertical:NO];
				[splitView setAutoresizingMask:[subview autoresizingMask]];
				
				// Create webView:
				self.webView = [[[WebView alloc] initWithFrame:[subview frame]] autorelease];
				[webView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
				[webView setShouldCloseWithWindow:YES];
				[webView setFrameLoadDelegate:self];
				
				// Substitute and connect the various views:
				[subview retain];
				[contentView replaceSubview:subview with:splitView];				
				[splitView addSubview:subview];
				[splitView addSubview:webView];				 
			}
		}
		
		[self reloadCurrentFilePath];
		
		[projectWindow addObserver:self forKeyPath:@"representedFilename" options:0 context:&SpWindowControllerContext];
	}
	return self;
}

- (void)dealloc
{
	[projectWindow removeObserver:self forKeyPath:@"representedFilename"];
	self.project = nil;
	self.projectWindow = nil;
	self.webView = nil;
	[super dealloc];
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

#pragma mark WebFrameLoadDelegate Informal Protocol

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]) {
        NSURL *url = [[[frame provisionalDataSource] request] URL];
		if([[url scheme] isEqual:SP_SCHEME] || [url isFileURL]) {
			NSString *path = [[url path] stringByStandardizingPath];
			if(![self.currentFilePath isEqual:path]) {
				self.currentFilePath = path;
				NSString *textMateURL = [NSString stringWithFormat:@"txmt://open?url=file://%@", path];
				NSURL *url = [NSURL URLWithString:textMateURL];
				NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
				[workspace openURL:url];
			}
		}
    }
}

@end
