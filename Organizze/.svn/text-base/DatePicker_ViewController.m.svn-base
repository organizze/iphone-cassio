//
//  DatePicker_ViewController.m
//  Organizze
//
//  Created by Cassio Rossi on 05/09/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "DatePicker_ViewController.h"

@implementation DatePicker_ViewController

#pragma mark - @synthesize

@synthesize transaction;
@synthesize datePicker;

#pragma mark - Memoru Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

	UIButton *leftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 35)];
	[leftButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
	leftButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
	[leftButton setTitleEdgeInsets:UIEdgeInsetsMake(0,3,0,0)];
	[leftButton setTitle:@"Cancelar" forState:UIControlStateNormal];
	[leftButton setBackgroundImage:[UIImage imageNamed:@"button_back.png"] forState:UIControlStateNormal];
	[leftButton setBackgroundImage:[UIImage imageNamed:@"button_back_selected.png"] forState:UIControlStateHighlighted];
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:leftButton] autorelease]];
	[leftButton release]; leftButton = nil;

	UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 35)];
	[rightButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
	rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
	[rightButton setTitleEdgeInsets:UIEdgeInsetsMake(0,3,0,0)];
	[rightButton setTitle:@"Salvar" forState:UIControlStateNormal];
	[rightButton setBackgroundImage:[UIImage imageNamed:@"button_background.png"] forState:UIControlStateNormal];
	[rightButton setBackgroundImage:[UIImage imageNamed:@"button_background_selected.png"] forState:UIControlStateHighlighted];
	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:rightButton] autorelease]];
	[rightButton release]; rightButton = nil;

	[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"fundo_claro.png"]]];

	[self.datePicker setDate:[[sharedMethods shared] dateFromFormattedString:[self.transaction valueForKey:@"date"] usingFormat:@"yyyy-MM-dd"]];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - View Methods

- (void)cancel {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)save {
	[self.transaction setValue:[NSNumber numberWithBool:([self.datePicker.date compare:[NSDate date]] == NSOrderedAscending)] forKey:@"done"];
	[self.transaction setValue:[[sharedMethods shared] formattedStringFromDate:self.datePicker.date usingFormat:@"yyyy-MM-dd"] forKey:@"date"];
	[self.transaction setValue:[NSDate date] forKey:@"updated_at"];
	[self.transaction setValue:[NSNumber numberWithBool:NO] forKey:@"synced"];

	[self.navigationController popViewControllerAnimated:YES];
}

@end
