//
//  WebViewController.m
//
//  Created by Cassio Rossi on 14/01/10.
//  Copyright 2010 Kazzio Software. All rights reserved.
//

#import "WebViewController.h"

@implementation WebViewController

#pragma mark - @synthsize

@synthesize webView, newsURL;

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	self.newsURL = nil;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
    [super dealloc];
}

#pragma mark - Web Methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self showRightNavigationItem:SHOW_SPIN];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self showRightNavigationItem:SHOW_NOTHING];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self showRightNavigationItem:SHOW_NOTHING];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	return YES;
}

#pragma mark - View Lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 35)];
	[backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
	backButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
	[backButton setTitleEdgeInsets:UIEdgeInsetsMake(0,3,0,0)];
	[backButton setTitle:@"Voltar" forState:UIControlStateNormal];
	[backButton setBackgroundImage:[UIImage imageNamed:@"button_back.png"] forState:UIControlStateNormal];
	[backButton setBackgroundImage:[UIImage imageNamed:@"button_back_selected.png"] forState:UIControlStateHighlighted];
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:backButton] autorelease]];
	[backButton release]; backButton = nil;

	[self showContent];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark - View Specifics Methods

// Função para mostrar o botão direito na NavigationBar, dependendo da situação
// Opções:	SHOW_SPIN			mostrar o spin wheel indicando que o aparelho está processando algo
//			SHOW_RIGHTBUTTON	mostrar o botão direito, com sua função
//			SHOW_NOTHING		não mostrar nada
- (void)showRightNavigationItem:(int)flag {
	if (flag == SHOW_SPIN) {
		UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[activityIndicator sizeToFit];
		activityIndicator.hidesWhenStopped = YES;
		activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
		[activityIndicator startAnimating];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:activityIndicator] autorelease];
		[activityIndicator release]; activityIndicator = nil;
	} else {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (void)showContent {
	NSURLRequest *request = [NSURLRequest requestWithURL:newsURL];
	[self.webView loadRequest:request];
}

- (void)resetContent {
	[self.webView loadHTMLString:@"<html><body>&nbsp;</body></html>" baseURL:[NSURL URLWithString:@""]];
}

- (void)back {
	[self dismissModalViewControllerAnimated:YES];
}

@end
