//
//  SpPlugin.h
//  Spanakopita
//
//  Created by Niko Matsakis on 1/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpInsertController.h"
#import "TextMate.h"

@interface SpPlugin : NSObject {
	NSMutableArray *spInsertControllers;
	NSMenu* windowMenu;
	NSMenuItem* showClockMenuItem;
}

- (void)installMenuItem;
- (void)uninstallMenuItem;
- (void)disposeWindows;

@end
