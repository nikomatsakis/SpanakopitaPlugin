/** See file LICENSE.txt for licensing information. **/

#import <Carbon/Carbon.h>
#import <QuickLook/QuickLook.h>
#import "SpUrlProtocol.h"
#import "SpErrors.h"
#import "SpPlugin.h"

@interface SpUrlProtocol()
- (void) loadFile;
- (BOOL) loadDirectory;
- (BOOL) loadFileAsIs;
- (BOOL) run:(NSArray*)words stdin:(BOOL)asStdin;
- (BOOL) interpretQuickLookFile;
@end

static NSData* SpImageToPng(CGImageRef image)
{
	// Based on code written by Jim Wrenholt, Nordic Software, Inc on 8/20/05
	// and found at http://www.carbondev.com/site/?page=Export+PNG
	NSMutableData *data = [NSMutableData data];
	CFStringRef type = kUTTypePNG;  //public.png
	size_t count = 1;
	CFDictionaryRef options = NULL;
	CGImageDestinationRef dest = CGImageDestinationCreateWithData((CFMutableDataRef)data, type, count, options);
	CGImageDestinationAddImage(dest, image, NULL);
	CGImageDestinationFinalize(dest);
	CFRelease(dest);
	return data;
}

@implementation SpUrlProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *)request
{
	NSLog(@"canInitWithRequest: %@", [request URL]);
	
	return [[[request URL] scheme] isEqual:SP_SCHEME];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
	NSLog(@"canonicalRequestForRequest: %@", [request URL]);
	
	// Probably should convert to absolute path.
	return request;
}

+ (void) initialize
{
	[super initialize];
	
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	[dictionary setObject:@"RUN_STDIN text/html UTF-8 ${FILTERPY}"
				   forKey:DEFAULTS_PREFIX @"sp"];

	[dictionary setObject:@"RUN image/svg+xml UTF-8 /usr/local/bin/dot -T svg ${PATH}"
				   forKey:DEFAULTS_PREFIX @"dot"];
	
	[dictionary setObject:@"PASSTHROUGH"
				   forKey:DEFAULTS_PREFIX @"txt"];
	
	[dictionary setObject:@"PASSTHROUGH"
				   forKey:DEFAULTS_PREFIX @"png"];
	
	[dictionary setObject:@"PASSTHROUGH"
				   forKey:DEFAULTS_PREFIX @"jpg"];
	
	[dictionary setObject:@"PASSTHROUGH"
				   forKey:DEFAULTS_PREFIX @"jpeg"];
	
	[dictionary setObject:@"PASSTHROUGH"
				   forKey:DEFAULTS_PREFIX @"html"];
	
	[dictionary setObject:@"PASSTHROUGH"
				   forKey:DEFAULTS_PREFIX @"txt"];
	
	[dictionary setObject:@"PASSTHROUGH"
				   forKey:DEFAULTS_PREFIX @"DEFAULT"];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:dictionary];
}

- (void) startLoading
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *url = [[self request] URL];
	NSString *path = [url path];	
	BOOL isDirectory;
	
	if([fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
		if(!isDirectory) {
			[self loadFile];
		} else {
			[self loadDirectory];
		}
	} else {
		[[self client] URLProtocol:self
				  didFailWithError:[NSError errorWithDomain:SP_ERROR_DOMAIN
													   code:SP_DOES_NOT_EXIST
												   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:NSLocalizedString(@"No such file: %@", @""), path],
															 NSLocalizedDescriptionKey,
															 nil]]];
	}
}

- (void) loadFile
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *path = [[[self request] URL] path];
	BOOL stopped;
	
	if([fileManager isReadableFileAtPath:path]) {
		NSString *ext = [path pathExtension];
		NSString *key = [DEFAULTS_PREFIX stringByAppendingString:[ext lowercaseString]];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *configuration = [defaults objectForKey:key];
		if(!configuration)
			configuration = [defaults objectForKey:DEFAULTS_PREFIX @"DEFAULT"];
		
		NSArray *words = [configuration componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		NSString *cmd = [words objectAtIndex:0];
		if([cmd isEqual:@"RUN"])
			stopped = [self run:words stdin:NO];
		else if([cmd isEqual:@"RUN_STDIN"])
			stopped = [self run:words stdin:YES];
		else
			stopped = [self loadFileAsIs];
	} else {
		[[self client] URLProtocol:self
				  didFailWithError:[NSError errorWithDomain:SP_ERROR_DOMAIN
													   code:SP_NOT_READABLE
												   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:NSLocalizedString(@"Not readable: %@", @""), path],
															 NSLocalizedDescriptionKey,
															 nil]]];
		stopped = NO;
	}	
	
	if(stopped) {
		// do we need to take some action if we aborted early?
	}	   
}

- (NSString*) subst:(NSString*)input
{
	NSRange range = [input rangeOfString:@"${FILTERPY}"];
	if(range.location != NSNotFound) {
		NSBundle *bundle = [NSBundle bundleForClass:[SpPlugin class]];
		NSString *filterPy = [bundle pathForResource:@"filter" ofType:@"py"];
		input = [input stringByReplacingOccurrencesOfString:@"${FILTERPY}" withString:filterPy];
	}
	
	range = [input rangeOfString:@"${PATH}"];
	if(range.location != NSNotFound) {
		NSString *path = [[[self request] URL] path];
		input = [input stringByReplacingOccurrencesOfString:@"${PATH}" withString:path];
	}
	
	return input;
}

- (BOOL) loadFileAsIs
{
	if(stop)
		return YES;
	
	NSString *path = [[[self request] URL] path];
	NSURL *fileURL = [NSURL fileURLWithPath:path];
	NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
	
	[[self client] URLProtocol:self
		wasRedirectedToRequest:request
			  redirectResponse:[[[NSURLResponse alloc] initWithURL:[[self request] URL]
														  MIMEType:@"text/plain" 
											 expectedContentLength:-1
												  textEncodingName:@"UTF-8"] autorelease]];
	return NO;
}

- (BOOL) runCommand:(NSString*)cmd 
		  arguments:(NSArray*)arguments 
		   mimeType:(NSString*)mimeType
			encoding:(NSString*)encoding
			  input:(id)input
{
	NSPipe *output = [NSPipe pipe];
	
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:cmd];
	[task setArguments:arguments];
	[task setStandardOutput:output];
	if(input)
		[task setStandardInput:input];
	[task launch];
	
	NSData *data = [[output fileHandleForReading] readDataToEndOfFile];
	
	[task waitUntilExit];
	int status = [task terminationStatus];
	
	if (status == 0) {
		[[self client] URLProtocol:self
				didReceiveResponse:[[[NSURLResponse alloc] initWithURL:[[self request] URL]									 
															  MIMEType:mimeType
												 expectedContentLength:[data length]
													  textEncodingName:encoding] autorelease]
				cacheStoragePolicy:NSURLCacheStorageNotAllowed];		
		
		[[self client] URLProtocol:self didLoadData:data];
		[[self client] URLProtocolDidFinishLoading:self];		  
	} else {
		[[self client] URLProtocol:self
				  didFailWithError:[NSError errorWithDomain:SP_ERROR_DOMAIN
													   code:SP_TXT2TAGS_FAILED
												   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:NSLocalizedString(@"Executing %@ failed with status %d", @""),
															  cmd, status],
															 NSLocalizedDescriptionKey,
															 nil]]];
	}
	
	return NO;
}

- (BOOL) run:(NSArray*)words stdin:(BOOL)asStdin
{
	NSString *path = [[[self request] URL] path];	
	NSString *mimeType = [words objectAtIndex:1];
	NSString *encoding = [words objectAtIndex:2];
	
	NSString *cmd = [words objectAtIndex:3];
	NSMutableArray *args = [NSMutableArray arrayWithCapacity:[words count] - 4];
	
	cmd = [self subst:cmd];
	for(int i = 4, c = [words count]; i < c; i++)
		[args addObject:[self subst:[words objectAtIndex:i]]];
	
	NSFileHandle *input;
	if(asStdin)
		input = [NSFileHandle fileHandleForReadingAtPath:path];
	else
		input = [NSFileHandle fileHandleWithNullDevice];
	
	NSLog(@"Spanakopita: Processing %@ with command %@ with arguments %@ stdin=%d",
		  path, cmd, args, asStdin);
	
	return [self runCommand:cmd arguments:args mimeType:mimeType encoding:encoding input:input];
}


/*
- (BOOL) realQuickLook
{
	
	id QLPreviewCreate(CFAllocatorRef allocator, CFURLRef url,  CFDictionaryRef options);
	id QLPreviewCopyBitmapImage(id preview);
	id QLPreviewCopyData(id preview);
	NSString* QLPreviewGetPreviewType(id preview);
	id QLPreviewCopyProperties(id preview);
	
	- (NSData *)getDataForFile:(NSString *)path
	{
		
		NSURL *fileURL = [NSURL fileURLWithPath:path];
		
		id preview = QLPreviewCreate(kCFAllocatorDefault, fileURL, 0);
		
		if (preview)
		{
			NSString* previewType = QLPreviewGetPreviewType(preview);
			
			if ([previewType isEqualToString:@"public.webcontent"])
			{
				// this preview is HTML data
				return QLPreviewCopyData(preview);
			}
			else
			{
				NSLog(@"this type is: %@", previewType);
				// do something else
			}
			
		}
		
		return nil;
	}	
}
*/

- (BOOL) interpretQuickLookFile
{
	NSURL *url = [[self request] URL];
	
	// Try quicklook:	
	CGSize maxSize = CGSizeMake(512, 512); // XXX
	NSURL *fileUrl = [NSURL fileURLWithPath:[url path]];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithFloat:512.0],
							 kQLThumbnailOptionScaleFactorKey,
							 nil];
	CGImageRef image = QLThumbnailImageCreate(CFAllocatorGetDefault(), (CFURLRef)fileUrl, maxSize, (CFDictionaryRef)options);
	
	NSData *data;
	if(image != NULL) {
		data = SpImageToPng(image);
		CFRelease(image);
	} else {	
		// No QL?  Try Finder icon:
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSImage *icon = [workspace iconForFile:[url path]];
		NSRect rect = NSMakeRect(0, 0, 256, 256);
		image = [icon CGImageForProposedRect:&rect context:[NSGraphicsContext currentContext] hints:nil];
		data = SpImageToPng(image);
	}
	
	[[self client] URLProtocol:self
			didReceiveResponse:[[[NSURLResponse alloc] initWithURL:[[self request] URL]									 
														  MIMEType:@"image/png" 
											 expectedContentLength:[data length]
												  textEncodingName:@"UTF-8"] autorelease]
			cacheStoragePolicy:NSURLCacheStorageNotAllowed];	
	[[self client] URLProtocol:self
				   didLoadData:data];
	
	return NO;
}

- (BOOL) loadDirectory
{
	return [self loadFileAsIs]; // XXX
}

- (void) stopLoading
{
	stop = YES;
}

@end
