#import "SpNode.h"

@implementation SpNode

- (id) initWithPath:(NSString *)aPath
{
	if((self = [super init])) {
		path = [aPath retain];
		[self refresh];
	}
	return self;
}

- (void) dealloc
{
	[path release];
	[children release];
	[super dealloc];
}

- (NSString*)path
{
	return path;
}

- (NSString*)name
{
	return [path lastPathComponent];
}

- (BOOL)isLeaf
{
	return !isDirectory;
}

- (NSArray*)children
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if(isDirectory && children == nil) {
		NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:nil];
		if(contents) {
			NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[contents count]];
			for(NSString *name in contents) {
				[array addObject:[[SpNode alloc] initWithPath:[path stringByAppendingPathComponent:name]]];
			}
			children = array;
		} else {
			children = [[NSArray array] retain];
		}
	}
	return children;
}

- (void)refresh
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[self willChangeValueForKey:@"isLeaf"];
	[self willChangeValueForKey:@"children"];
	isDirectory = NO;
	[children release], children = nil;
	[fileManager fileExistsAtPath:path isDirectory:&isDirectory];
	[self didChangeValueForKey:@"isLeaf"];
	[self didChangeValueForKey:@"children"];
}

@end
