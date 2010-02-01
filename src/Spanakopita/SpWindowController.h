/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>
#import "SpNode.h"

@interface SpWindowController : NSWindowController {
	SpNode *rootNode;
}

- initWithPath:(NSString*)path;

@end
