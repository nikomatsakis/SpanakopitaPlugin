/** See file LICENSE.txt for licensing information. **/

#import "SpWindowController.h"
#import "SpInsertController.h"

int SpWindowControllerContext;

@interface SpWindowController()
@property(retain) SpNode *rootNode;
@property(retain) SpInsertController *insertController;
@property(assign) NSScrollView *textScrollView;
@property(retain) NSTreeController *fileSystem;
@property(retain) NSString *editPath;
@property(assign) NSStringEncoding editEncoding;
@end

@implementation SpWindowController

@synthesize rootNode, insertController, textScrollView, fileSystem, editPath, editEncoding;

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
	self.editPath = nil;
	[super dealloc];
}

- (void) saveCurrentFile
{
	if(editPath) {
		
	}
}

- (NSAttributedString*)attributize:(NSString*)string
{
	NSFont *font = [NSFont fontWithName:@"Monaco" size:12];	
	return [[[NSAttributedString alloc] initWithString:string attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																		  font, NSFontAttributeName,
																		  nil]] autorelease];
}

- (void) selectFile: (NSString*) path
{
	[self saveCurrentFile];
	
	[[self window] setRepresentedFilename:path];
	
	[[self window] setTitle:[path lastPathComponent]];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory;
	if([fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
		if(isDirectory) {
			[[textView textStorage] setAttributedString:[self attributize:@"(Directory)"]];
			[textView setEditable:NO];
			self.editPath = nil;
		} else {
			NSError *error;			
			NSString *fileString = [NSString stringWithContentsOfFile:path usedEncoding:&editEncoding error:&error];
			if(fileString) {
				NSAttributedString *attString = [self attributize:fileString];
				[[textView textStorage] setAttributedString:attString];
				[textView setEditable:YES];
				self.editPath = path;
			} else {
				NSString *string = [error localizedDescription];
				NSAttributedString *attString = [self attributize:string];
				[[textView textStorage] setAttributedString:attString];
				[textView setEditable:NO];
				self.editPath = nil;
			}
		}
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &SpWindowControllerContext) {
		NSArray *objects = [fileSystem selectedObjects];
		if([objects count] >= 1) {
			SpNode *node = [objects objectAtIndex:0];
			[self selectFile:node.path];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)changeToPath:(NSString*)path
{
	[self selectFile:path];
}

@end
