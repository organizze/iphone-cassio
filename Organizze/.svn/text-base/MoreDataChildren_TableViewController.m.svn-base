//
//  MoreDataChildren_TableViewController.m
//  Organizze
//
//  Created by Cassio Rossi on 06/09/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "MoreDataChildren_TableViewController.h"

@implementation MoreDataChildren_TableViewController

#pragma mark - @synthesize

@synthesize moreDataToShow, transaction, key;

#pragma mark - Memory Management

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
	
	[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
	[self.tableView setSeparatorColor:TABLESEPARATORCOLOR];
	[self.tableView setSectionHeaderHeight:12];
	[self.tableView setSectionFooterHeight:0];
	[self.tableView setRowHeight:44.0f];
	if ([self.tableView respondsToSelector:@selector(setBackgroundView:)]) {
		[self.tableView setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fundo_claro.png"]] autorelease]];
		[self.tableView setBackgroundColor:[UIColor clearColor]];
	} else {
		[self.tableView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"fundo_claro.png"]]];
	}

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return [self.moreDataToShow count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	}
	
	// Configure the cell...
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	cell.textLabel.text = [[[self.moreDataToShow objectAtIndex:indexPath.row] valueForKey:@"name"] description];
	if ([[[self.transaction valueForKey:key] description] isEqualToString:[[[self.moreDataToShow objectAtIndex:indexPath.row] valueForKey:@"id"] description]]) {
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}

	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[self.transaction setValue:[[self.moreDataToShow objectAtIndex:indexPath.row] valueForKey:@"id"] forKey:key];
	
	NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
	if ([context hasChanges]) {
		[self.transaction setValue:[NSDate date] forKey:@"updated_at"];
		[self.transaction setValue:[NSNumber numberWithBool:NO] forKey:@"synced"];
	}
	context = nil;
	
	[self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - View Methods

- (void)cancel {
	[self.navigationController popViewControllerAnimated:YES];
}

@end
