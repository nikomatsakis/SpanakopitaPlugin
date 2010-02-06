/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class SpInsertController;

@protocol SpInsertControllerDelegate
- (void) changeToPath:(NSString*)path;
- (void) unwrapRequested:(SpInsertController*)contr;
@end

@interface SpInsertController : NSObject {
	NSWindow *projectWindow;
	NSString *currentFilePath;	
	NSView *wrappedView;
	NSView *mainView;
	WebView *webView;
	id<SpInsertControllerDelegate> delegate;
	FSEventStreamRef eventStream;
}
@property(assign) NSWindow *projectWindow;
@property(copy) NSString *currentFilePath;
@property(retain) IBOutlet NSView *mainView;
@property(assign) IBOutlet WebView *webView;
@property(assign) id<SpInsertControllerDelegate> delegate;

- initWithProjectWindow:(NSWindow*)aWindow;
- (void) wrap:(NSView *)subview;
- (void) unwrap;
- (void)reloadCurrentFilePath;

- (IBAction)reload:(id)sender;
- (IBAction)remove:(id)sender;

@end
