//
//  SpWindowController.h
//  Spanakopita
//
//  Created by Niko Matsakis on 1/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SpWindowController : NSWindowController {
	id allEnvTarget;
}
@property(retain) id allEnvTarget;
@property(readonly) NSString *currentFilePath;

@end
