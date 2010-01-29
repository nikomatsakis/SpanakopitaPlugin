//
//  SpPlugin.m
//  Spanakopita
//
//  Created by Niko Matsakis on 1/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SpPlugin.h"


@implementation SpPlugin
- (id)initWithPlugInController:(id <TMPlugInController>)aController
{
	//	[NSWindowPoser poseAsClass:[NSWindow class]];
	
	NSLog(@"SpPlugin init");
	
	NSApp = [NSApplication sharedApplication];
	if(self = [super init])
		[self installMenuItem];
	return self;
}

- (void)dealloc
{
	[self uninstallMenuItem];
	[self disposeWindow];
	[super dealloc];
}

- (void)installMenuItem
{
	if(windowMenu = [[[[NSApp mainMenu] itemWithTitle:@"Window"] submenu] retain])
	{
		unsigned index = 0;
		NSArray* items = [windowMenu itemArray];
		for(int separators = 0; index != [items count] && separators != 2; index++)
			separators += [[items objectAtIndex:index] isSeparatorItem] ? 1 : 0;
		
		showClockMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Spanakopita" action:@selector(showSpanakopita:) keyEquivalent:@""];
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

- (NSString*)currentFilePath
{
	id target = [NSApp targetForAction:@selector(allEnvironmentVariables)];
	return [[target allEnvironmentVariables] objectForKey:@"TM_FILEPATH"];
}

- (void)showSpanakopita:(id)sender
{
	NSLog(@"Current file path: %@", [self currentFilePath]);
	if(!spWindowController)
	{
		spWindowController = [[SpWindowController alloc] init];
	}
	[spWindowController showWindow:self];
}

- (void)disposeWindow
{
	[spWindowController close];
	[spWindowController release];
	spWindowController = nil;
}

@end
