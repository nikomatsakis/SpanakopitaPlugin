/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface SpInsertController : NSObject {
	NSWindow *projectWindow;
	NSString *currentFilePath;	
	WebView *webView;
}
@property(assign) NSWindow *projectWindow;
@property(copy) NSString *currentFilePath;
@property(assign) WebView *webView;

+ insertIntoProjectWindow:(NSWindow*)aWindow;

- initWithProjectWindow:(NSWindow*)aWindow;

- (void)reloadCurrentFilePath;

@end
