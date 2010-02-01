#import <Cocoa/Cocoa.h>

@interface SpNode : NSObject {
	NSString *path;
	BOOL exists, isDirectory;
	NSArray *children;
}
- initWithPath:(NSString*)path;
- (NSString*)name;
- (BOOL)isLeaf;
- (NSArray*)children;
- (void)refresh;
@end
