//
//  SpWindowController.h
//  Spanakopita
//
//  Created by Niko Matsakis on 1/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "TextMate.h"

@interface SpInsertController : NSObject {
	OakProjectController *project;
	NSWindow *projectWindow;
	NSString *currentFilePath;	
	WebView *webView;
}
@property(retain) OakProjectController *project;
@property(retain) NSWindow *projectWindow;
@property(copy) NSString *currentFilePath;
@property(retain) IBOutlet WebView *webView;

- initWithProjectController:(OakProjectController*)aProject
			  projectWindow:(NSWindow*)aWindow;

- (void)reloadCurrentFilePath;

@end
