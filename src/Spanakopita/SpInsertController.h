/** See file LICENSE.txt for licensing information. **/

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
@property(retain) WebView *webView;

- initWithProjectController:(OakProjectController*)aProject
			  projectWindow:(NSWindow*)aWindow;

- (void)reloadCurrentFilePath;

@end
