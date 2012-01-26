//
//  MoreData_TableViewController.m
//  Organizze
//
//  Created by Cassio Rossi on 05/09/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "MoreData_TableViewController.h"
#import "MoreDataChildren_TableViewController.h"

@implementation MoreData_TableViewController

#pragma mark - @synthesize

@synthesize moreDataToShow, childrenArray, transaction, key;
@synthesize versaoMais;

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

	// Verificar se tem "FILHOS"
	NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Tags" inManagedObjectContext:context]];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"parent_id != 0"]];

	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES] autorelease];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
	sortDescriptor = nil;
	
	self.childrenArray = [context executeFetchRequest:fetchRequest error:nil];
	[fetchRequest release]; fetchRequest = nil; context = nil;
	
}

- (void)viewDidUnload {
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
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
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	}

	// Configure the cell...
	[cell setAccessoryType:UITableViewCellAccessoryNone];

	if ([[self.moreDataToShow objectAtIndex:indexPath.row] isKindOfClass:[NSString class]]) {
		cell.textLabel.text = [self.moreDataToShow objectAtIndex:indexPath.row];
		if ([[self.transaction valueForKey:key] boolValue] == indexPath.row) {
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		}

	} else {
		cell.textLabel.text = [[[self.moreDataToShow objectAtIndex:indexPath.row] valueForKey:@"name"] description];
		if ([self.key isEqualToString:@"account_id"]) {
			NSString *detailText = @"Conta Corrente";
			if ([[[[self.moreDataToShow objectAtIndex:indexPath.row] valueForKey:@"kind"] description] isEqualToString:@"others"]) {
				detailText = @"Outros";
			} else if ([[[[self.moreDataToShow objectAtIndex:indexPath.row] valueForKey:@"kind"] description] isEqualToString:@"savings"]) {
				detailText = @"Conta Poupança";
			}
			cell.detailTextLabel.text = detailText;
			detailText = nil;
		}
		if ([[[self.transaction valueForKey:key] description] isEqualToString:[[[self.moreDataToShow objectAtIndex:indexPath.row] valueForKey:@"id"] description]]) {
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		}

		if (versaoMais) {
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent_id == %@", [[self.moreDataToShow objectAtIndex:indexPath.row] valueForKey:@"id"]];
			NSArray *filteredArray = [self.childrenArray filteredArrayUsingPredicate:predicate];
			if ([filteredArray count] > 0) {
				[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
			}
		}
	}

	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];

	BOOL showChildren = NO;

	if (versaoMais) {
		if ([[self.moreDataToShow objectAtIndex:indexPath.row] isKindOfClass:[NSManagedObject class]]) {
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent_id == %@", [[self.moreDataToShow objectAtIndex:indexPath.row] valueForKey:@"id"]];
			NSPredicate *otherPredicate = [NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]];
			NSArray *filteredArray = [self.childrenArray filteredArrayUsingPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, otherPredicate, nil]]];
			if ([filteredArray count] > 0) {
				showChildren = YES;
				
				MoreDataChildren_TableViewController *anotherViewController = [[[MoreDataChildren_TableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
				[anotherViewController setTitle:@"Categoria"];
				[anotherViewController setTransaction:self.transaction];
				[anotherViewController setMoreDataToShow:filteredArray];
				[anotherViewController setKey:self.key];
				[self.navigationController pushViewController:anotherViewController animated:YES];
				anotherViewController = nil;
			}
			filteredArray = nil; predicate = nil; otherPredicate = nil;
		}
	}

	if (!showChildren) {
		if ([[self.moreDataToShow objectAtIndex:indexPath.row] isKindOfClass:[NSString class]]) {
			[self.transaction setValue:[NSNumber numberWithBool:indexPath.row] forKey:key];
		} else {
			[self.transaction setValue:[[self.moreDataToShow objectAtIndex:indexPath.row] valueForKey:@"id"] forKey:key];
		}

		NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
		if ([context hasChanges]) {
			[self.transaction setValue:[NSDate date] forKey:@"updated_at"];
			[self.transaction setValue:[NSNumber numberWithBool:NO] forKey:@"synced"];
		}
		context = nil;

		[self.navigationController popViewControllerAnimated:YES];
	}
}

#pragma mark - View Methods

- (void)cancel {
	[self.navigationController popViewControllerAnimated:YES];
}

@end
