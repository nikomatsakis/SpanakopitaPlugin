//
//  SpPlugin.h
//  Spanakopita
//
//  Created by Niko Matsakis on 1/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpWindowController.h"

@protocol TMPlugInController
- (float)version;
@end

@interface SpPlugin : NSObject {
	SpWindowController* spWindowController;
	NSMenu* windowMenu;
	NSMenuItem* showClockMenuItem;	
}

- (void)installMenuItem;
- (void)uninstallMenuItem;
- (void)disposeWindow;

@end
