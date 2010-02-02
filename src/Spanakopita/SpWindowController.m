/** See file LICENSE.txt for licensing information. **/

#import "SpWindowController.h"
#import "SpInsertController.h"

int SpWindowControllerContext;

@interface SpWindowController()
@property(retain) SpNode *rootNode;
@property(retain) SpInsertController *insertController;
@property(assign) NSScrollView *textScrollView;
@property(retain) NSTreeController *fileSystem;
@end

@implementation SpWindowController

@synthesize rootNode, insertController, textScrollView, fileSystem;

- (id) initWithPath:(NSString *)path
{
	if((self = [super initWithWindowNibName:@"SpanakopitaWindow"])) {
		rootNode = [[SpNode alloc] initWithPath:path];
		[self loadWindow];
		
		insertController = [[SpInsertController alloc] initWithProjectWindow:[self window]];
		[insertController wrap:textScrollView];
		insertController.delegate = self;
		
		[fileSystem addObserver:self forKeyPath:@"selectionIndexPaths" options:0 context:&SpWindowControllerContext];
	}
	return self;
}

- (void) dealloc
{
	self.rootNode = nil;
	self.insertController = nil;
	self.textScrollView = nil;
	self.fileSystem = nil;
	[super dealloc];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &SpWindowControllerContext) {
		NSArray *objects = [fileSystem selectedObjects];
		if([objects count] >= 1) {
			SpNode *node = [objects objectAtIndex:0];
			NSLog(@"Current Node: %@", node.path);
			[[self window] setRepresentedFilename:node.path];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)changeToPath:(NSString*)path
{
	[[self window] setRepresentedFilename:path];	  
}

@end
