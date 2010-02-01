/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "TextMate.h"

@interface SpInsertController : NSObject {
	NSWindow *projectWindow;
	NSString *currentFilePath;	
	WebView *webView;
}
@property(retain) NSWindow *projectWindow;
@property(copy) NSString *currentFilePath;
@property(retain) WebView *webView;

+ insertIntoProjectWindow:(NSWindow*)aWindow;

- initWithProjectWindow:(NSWindow*)aWindow;

- (void)reloadCurrentFilePath;

@end
