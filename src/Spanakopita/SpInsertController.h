/** See file LICENSE.txt for licensing information. **/

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@protocol SpInsertControllerDelegate
- (void) changeToPath:(NSString*)path;
@end


@interface SpInsertController : NSObject {
	NSWindow *projectWindow;
	NSString *currentFilePath;	
	NSView *mainView;
	WebView *webView;
	id<SpInsertControllerDelegate> delegate;
}
@property(assign) NSWindow *projectWindow;
@property(copy) NSString *currentFilePath;
@property(retain) IBOutlet NSView *mainView;
@property(assign) IBOutlet WebView *webView;
@property(assign) id<SpInsertControllerDelegate> delegate;

+ wrapTextMateEditorInProjectWindow:(NSWindow*)aWindow;

- initWithProjectWindow:(NSWindow*)aWindow;
- (void) wrap:(NSView *)subview;
- (void)reloadCurrentFilePath;

- (IBAction)reload:(id)sender;

@end
