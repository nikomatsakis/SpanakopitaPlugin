//
//  SpTest.h
//  Spanakopita
//
//  Created by Niko Matsakis on 1/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface SpTest : NSObject {
	WebView *webView;
	NSString *curPath;
}
@property(retain) IBOutlet WebView *webView;
@property(retain) NSString *curPath;

- (IBAction)load:(id)sender;
@end
