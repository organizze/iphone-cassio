//
//  WebViewController.h
//
//  Created by Cassio Rossi on 14/01/10.
//  Copyright 2010 Kazzio Software. All rights reserved.
//

@interface WebViewController : UIViewController <UIWebViewDelegate> {
	UIWebView	*webView;
	NSURL		*newsURL;
}

@property (nonatomic, assign) IBOutlet UIWebView *webView;
@property (nonatomic, retain) NSURL *newsURL;

- (void)showRightNavigationItem:(int)flag;
- (void)showContent;
- (void)resetContent;
- (void)back;

@end
