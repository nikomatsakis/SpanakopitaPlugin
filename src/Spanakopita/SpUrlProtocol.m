//
//  SpUrlLoader.m
//  Spanakopita
//
//  Created by Niko Matsakis on 1/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>
#import <QuickLook/QuickLook.h>
#import "SpUrlProtocol.h"
#import "SpErrors.h"
#import "SpPlugin.h"

@interface SpUrlProtocol()
- (void) loadFile;
- (BOOL) loadDirectory;
- (BOOL) loadFileAsIs;
- (BOOL) interpretSpFile;
- (BOOL) interpretDotFile;
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
	return [[[request URL] scheme] isEqual:SP_SCHEME];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
	// Probably should convert to absolute path.
	return request;
}

- (void) startLoading
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *url = [[self request] URL];
	NSString *path = [url path];	
	BOOL isDirectory;
	
	NSLog(@"startLoading: %@", path);
	
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
		ext = [ext lowercaseString];
		NSSet *asIsExtensions = [NSSet setWithObjects:
								 @"png", @"jpg", @"jpeg", @"html", @"txt", nil];
		
		if([asIsExtensions containsObject:ext]) {
			stopped = [self loadFileAsIs];
		} else if ([ext isEqual:@"sp"]) {
			stopped = [self interpretSpFile];
		} else if ([ext isEqual:@"dot"]) {
			stopped = [self interpretDotFile];
		} else {
			stopped = [self interpretQuickLookFile];
		}
	} else {
		[[self client] URLProtocol:self
				  didFailWithError:[NSError errorWithDomain:SP_ERROR_DOMAIN
													   code:SP_NOT_READABLE
												   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:NSLocalizedString(@"Not readable: %@", @""), path],
															 NSLocalizedDescriptionKey,
															 nil]]];
	}
	
	if(stopped) { 
		// ...?
	}
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
	
//	NSError *error;
//	NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
//	if(!data) {
//		[[self client] URLProtocol:self
//				  didFailWithError:[NSError errorWithDomain:SP_ERROR_DOMAIN
//													   code:SP_NOT_READABLE
//												   userInfo:error]];		
//	} else {
//		[[self client] URLProtocol:self
//				didReceiveResponse:[[[NSURLResponse alloc] initWithURL:[[self request] url]									 
//															  MIMEType:<#(NSString *)MIMEType#> 
//												 expectedContentLength:[data length]
//													  textEncodingName:nil] autorelease]
//				cacheStoragePolicy:nil];
//		 
//	}
}

- (BOOL) runCommand:(NSString*)cmd 
		  arguments:(NSArray*)arguments 
		   mimeType:(NSString*)mimeType
			  input:(id)input
{
	NSPipe *output = [NSPipe pipe];
	
	NSLog(@"cmd: %@ arguments: %@", cmd, arguments);
	
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
		/* XXX Make text encoding configurable. */
		
		[[self client] URLProtocol:self
				didReceiveResponse:[[[NSURLResponse alloc] initWithURL:[[self request] URL]									 
															  MIMEType:mimeType
												 expectedContentLength:[data length]
													  textEncodingName:@"UTF-8"] autorelease]
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

- (BOOL) interpretSpFile
{
	if(stop)
		return YES;
	
	NSString *path = [[[self request] URL] path];
	
	/* XXX Get input from TextMate buffer if open */
	NSFileHandle *input = [NSFileHandle fileHandleForReadingAtPath:path];
	
	/* XXX Either bring the python in-process (less configurable) or
	 *     make the path and arguments configurable somehow. */
	
	NSBundle *bundle = [NSBundle bundleForClass:[SpPlugin class]];
	NSString *txt2tagsPath = [bundle pathForResource:@"txt2tags25" ofType:@"py"];
	NSArray *arguments = [NSArray arrayWithObjects:@"-t", @"html", @"-i", @"-", nil];
	
	return [self runCommand:txt2tagsPath arguments:arguments mimeType:@"text/html" input:input];
}

- (BOOL) interpretDotFile
{
	if(stop)
		return YES;
	
	/* XXX Make path and arguments configurable */
	NSString *path = [[[self request] URL] path];
	NSArray *arguments = [NSArray arrayWithObjects:@"-T", @"png", path, nil];	
	return [self runCommand:@"/usr/local/bin/dot" arguments:arguments mimeType:@"text/png" input:[NSFileHandle fileHandleWithNullDevice]];
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
