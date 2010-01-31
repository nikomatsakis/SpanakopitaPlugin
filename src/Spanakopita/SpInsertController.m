//
//  SpWindowController.m
//  Spanakopita
//
//  Created by Niko Matsakis on 1/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SpWindowController.h"
#import "TextMate.h"

int SpWindowControllerContext;

@implementation SpWindowController

@synthesize project, projectWindow, currentFilePath;

- initWithProjectController:(OakProjectController*)aProject
			  projectWindow:(NSWindow*)aWindow
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"Spanakopita" ofType:@"nib"];
	if((self = [super initWithWindowNibPath:path owner:self])) {
		self.project = aProject;
		self.projectWindow = aWindow;
		
		// Have to insert 
		
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
	[super dealloc];
}

- (void)reloadCurrentFilePath
{
	self.currentFilePath = [self.projectWindow representedFilename];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"sp://%@", currentFilePath]];
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
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

@end
