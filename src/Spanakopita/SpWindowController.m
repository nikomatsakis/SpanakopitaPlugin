//
//  SpWindowController.m
//  Spanakopita
//
//  Created by Niko Matsakis on 1/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SpWindowController.h"

@interface NSObject (SpTextMate)
- (id)allEnvironmentVariables;
@end

@implementation SpWindowController

@synthesize allEnvTarget;

- init
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"Spanakopita" ofType:@"nib"];
	[super initWithWindowNibPath:path owner:self];
	self.allEnvTarget = [NSApp targetForAction:@selector(allEnvironmentVariables)];
	NSLog(@"allEnvTarget = %@", allEnvTarget);
	return self;
}

- (void)dealloc
{
	self.allEnvTarget = nil;
	[super dealloc];
}

+ (NSSet *) keyPathsForValuesAffectingCurrentFilePath
{
	return [NSSet setWithObject:@"allEnvTarget.allEnvironmentVariables.TM_FILEPATH"];
}

- (NSString*)currentFilePath
{
	return [[allEnvTarget allEnvironmentVariables] objectForKey:@"TM_FILEPATH"];
}

@end
