/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>
#import "SpNode.h"
#import "SpInsertController.h"

@interface SpWindowController : NSWindowController <SpInsertControllerDelegate> {
	SpNode *rootNode;
	SpInsertController *insertController;
	IBOutlet NSScrollView *textScrollView;
	IBOutlet NSTextView *textView;
	IBOutlet NSTreeController *fileSystem;
	
	NSString *editPath;
	NSStringEncoding editEncoding;
}

- initWithPath:(NSString*)path;
- (void)changeToPath:(NSString *)path;

@end
