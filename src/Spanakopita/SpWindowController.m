/** See file LICENSE.txt for licensing information. **/

#import "SpWindowController.h"
#import "SpInsertController.h"

@implementation SpWindowController

- (id) initWithPath:(NSString *)path
{
	if((self = [super initWithWindowNibName:@"SpanakopitaWindow"])) {
		rootNode = [[SpNode alloc] initWithPath:path];
	}
	return self;
}

- (void) windowDidLoad
{
//	[SpInsertController insertIntoProjectWindow:[self window]];
}
				
@end
