//
//  Movimentacoes_TableViewController.m
//  Organizze
//
//  Created by Cassio Rossi on 11/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "Movimentacoes_ViewController.h"
#import "Configuracoes_TableViewController.h"
#import "AddMovimento_TableViewController.h"

@implementation Movimentacoes_ViewController

#pragma mark - @synthesize

@synthesize movimentosCell;
@synthesize tableView, headerLabel, currentMonth, resumeView, detailsView, footerLabel, incomeLabel, expenseLabel, saldoInicial;
@synthesize noDataView;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize arrow;
@synthesize previousView, previousLabel;
@synthesize tooltipView;

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	// Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	self.saldoInicial = nil;
	self.previousView = nil;
	self.previousLabel = nil;
	self.incomeLabel = nil;
	self.expenseLabel = nil;
	self.detailsView = nil;
	self.resumeView = nil;
	self.headerLabel = nil;
	self.footerLabel = nil;
	self.currentMonth = nil;
	self.movimentosCell = nil;
	self.noDataView = nil;
	self.tooltipView = nil;
	self.tableView = nil;

	[__fetchedResultsController release];
	[__managedObjectContext release];

	[super dealloc];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackNotifications:) name:@"GETNEWDATA" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackNotifications:) name:@"SYNCHRONIZE" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackNotifications:) name:@"ABORTSYNC" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackNotifications:) name:@"HASNEWDATA" object:nil];

	[self.navigationItem setTitleView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_navbar.png"]] autorelease]];

	UIButton *leftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
	[leftButton addTarget:self action:@selector(showConfig) forControlEvents:UIControlEventTouchUpInside];
	[leftButton setImage:[UIImage imageNamed:@"button_config.png"] forState:UIControlStateNormal];
	[leftButton setImage:[UIImage imageNamed:@"button_config_selected.png"] forState:UIControlStateHighlighted];
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:leftButton] autorelease]];
	[leftButton release]; leftButton = nil;

	UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
	[rightButton addTarget:self action:@selector(addRecord:) forControlEvents:UIControlEventTouchUpInside];
	[rightButton setImage:[UIImage imageNamed:@"button_add.png"] forState:UIControlStateNormal];
	[rightButton setImage:[UIImage imageNamed:@"button_add_selected.png"] forState:UIControlStateHighlighted];
	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:rightButton] autorelease]];
	[rightButton release]; rightButton = nil;

	[self.tableView setScrollsToTop:YES];
	[self.tableView setSeparatorColor:LINESEPARATORCOLOR];
	[self.tableView setSectionHeaderHeight:27.0f];
	[self.tableView setRowHeight:47.0f];
	[self.tableView setBackgroundColor:[UIColor whiteColor]];
	if ([self.tableView respondsToSelector:@selector(setBackgroundView:)]) {
		[self.tableView setBackgroundView:nil];
	}

	self.managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];			

	months = 0;
	[self setNewDate];
	[self showHideDetailView];

	// Verificar se existe algúm dado no BD para não mostrar TOOLTIP
	// Get existing data
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.managedObjectContext]];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]]];

	NSArray *transactionsObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	[self.tooltipView setHidden:([transactionsObject count] > 0)];
	transactionsObject = nil;
	
	[fetchRequest release]; fetchRequest = nil;

	// Se tiver logado e houver rede, fazer SYNC
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"CREDENTIALS"] != nil) {
		[self synchronizeData];
	}
}

- (void)viewDidUnload {
	[super viewDidUnload];
	// Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
	// For example: self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	[self updateDetailView];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableView Methods

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[self.fetchedResultsController sections] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> theSection = [[self.fetchedResultsController sections] objectAtIndex:section];

	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.sectionHeaderHeight)] autorelease];
	[headerView setBackgroundColor:[UIColor whiteColor]];

	UIImageView *image = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divisor.png"]] autorelease];
	[headerView addSubview:image];
	image = nil;

	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, headerView.frame.size.width - 20, headerView.frame.size.height)] autorelease];
	[label setBackgroundColor:[UIColor clearColor]];
	[label setTextColor:GRAYTEXTCOLOR];
	[label setFont:[UIFont systemFontOfSize:12]];
	[label setText:[[sharedMethods shared] formattedStringFromString:[theSection name] withFormat:@"yyyy-MM-dd" andDisplayFormat:@"dd/MM' - 'eeee"]];
	
	[headerView addSubview:label];
	label = nil;

	return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	Movimentos_TableCell *cell = (Movimentos_TableCell *)[self.tableView dequeueReusableCellWithIdentifier:@"Movimentos_TableCell"];
	if (cell == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"Movimentos_TableCell" owner:self options:nil];
		cell = self.movimentosCell;
		self.movimentosCell = nil;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	// Configure the cell.
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

#pragma mark - UITableView Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];

	if (![[[self.fetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"start_result"] boolValue] &&
		![[[self.fetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"transfer"] boolValue]) {
		[self addRecord:[self.fetchedResultsController objectAtIndexPath:indexPath]];
	}
}

- (void)configureCell:(Movimentos_TableCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	if (indexPath != nil) {
		NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
		
		if (managedObject != nil) {
			[cell.background setBackgroundColor:[UIColor whiteColor]];
			NSDate *today = [[sharedMethods shared] dateFromFormattedString:[[sharedMethods shared] formattedStringFromDate:[NSDate date] usingFormat:@"yyyy-MM-dd"] usingFormat:@"yyyy-MM-dd"];
			if (![[managedObject valueForKey:@"done"] boolValue] && 
				[[[sharedMethods shared] dateFromFormattedString:[managedObject valueForKey:@"date"] usingFormat:@"yyyy-MM-dd"] compare:today] == NSOrderedAscending) {
				[cell.background setBackgroundColor:YELLOWCOLOR];
			}
			today = nil;
			
			NSString *parcelas = [NSString stringWithFormat:@" %d/%d", [[managedObject valueForKey:@"repeat_index"] integerValue], [[managedObject valueForKey:@"repeat_total"] integerValue]];
			NSString *description = [NSString stringWithFormat:@"%@%@", [[managedObject valueForKey:@"description_text"] description], ([[[managedObject valueForKey:@"repeat_type"] description] isEqualToString:@"bills"] ? @"" : parcelas)];
			[cell.movimento setText:description];
			description = nil; parcelas = nil;
			
			[cell.valor setText:[[sharedMethods shared] currencyFormat:[[managedObject valueForKey:@"ammount"] description] usingSymbol:@"R$ " andDigits:2]];
			
			if ([[managedObject valueForKey:@"income"] boolValue]) {
				[cell.pago setText:([[managedObject valueForKey:@"done"] boolValue] ? @"recebi" : @"")];
				[cell.tag setImage:[UIImage imageNamed:@"income@2x.png"]];
			} else {
				[cell.pago setText:([[managedObject valueForKey:@"done"] boolValue] ? @"paguei" : @"")];
				[cell.tag setImage:[UIImage imageNamed:@"expense@2x.png"]];
			}
			
			if ([[managedObject valueForKey:@"transfer"] boolValue]) {
				[cell.tag setImage:[UIImage imageNamed:@"transfer@2x.png"]];
				[cell.pago setText:@""];
			}
			
			if ([[managedObject valueForKey:@"start_result"] boolValue]) {
				[cell.tag setImage:[UIImage imageNamed:@"other@2x.png"]];
				[cell.pago setText:@""];
				NSString *valor = [[managedObject valueForKey:@"ammount"] description];
				[cell.valor setText:[[sharedMethods shared] currencyFormat:([[managedObject valueForKey:@"income"] boolValue] ? valor : [NSString stringWithFormat:@"-%@", valor]) usingSymbol:@"R$ " andDigits:2]];
				valor = nil;
			}
			
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			[fetchRequest setEntity:[NSEntityDescription entityForName:@"Tags" inManagedObjectContext:self.managedObjectContext]];
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"id == %@", [managedObject valueForKey:@"tag_id"]]];
			
			for (NSManagedObject *tagObject in [self.managedObjectContext executeFetchRequest:fetchRequest error:nil]) {
				[cell.categoria setText:[tagObject valueForKey:@"name"]];
				[cell.categoria setTextColor:GRAYOVERWHITECOLOR];
			}
			[fetchRequest release]; fetchRequest = nil;
		}
	}
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
	if (__fetchedResultsController != nil) {
		return __fetchedResultsController;
	}

	// Set up the fetched results controller.
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[NSFetchedResultsController deleteCacheWithName:@"Root"];
	// Edit the entity name as appropriate.
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.managedObjectContext]];

	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];
	[fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
																				   [NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]],
																				   [NSPredicate predicateWithFormat:@"date BEGINSWITH %@", self.currentMonth], 
																				   nil]]];

	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
	sortDescriptor = nil;

	// Edit the section name key path and cache name if appropriate.
	// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"date" cacheName:@"Root"];
	aFetchedResultsController.delegate = self;
	self.fetchedResultsController = aFetchedResultsController;

	[aFetchedResultsController release]; aFetchedResultsController = nil;
	[fetchRequest release]; fetchRequest = nil;

	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
		/*
		Replace this implementation with code to handle the error appropriately.
		abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		*/
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}

	[UIView animateWithDuration:0.4f
					 animations:^{
						 [UIView setAnimationTransition:(downOrientation ? UIViewAnimationTransitionCurlDown : UIViewAnimationTransitionCurlUp) forView:self.view cache:NO];
						 [self.tableView reloadData];
					 }
	 ];

	return __fetchedResultsController;
}    

#pragma mark - Fetched results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeUpdate:
			[self configureCell:(Movimentos_TableCell *)[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;

		case NSFetchedResultsChangeMove:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView endUpdates];
	[self.tableView reloadData];
}

#pragma mark - Notification methods

// Função acessada quando NSNotificationCenter recebe um evento
- (void)trackNotifications:(NSNotification *)notification {
	if ([[notification name] isEqualToString:@"HASNEWDATA"]) {
		[self.noDataView setHidden:([[self.fetchedResultsController sections] count] > 0)];
	}

	if ([[notification name] isEqualToString:@"GETNEWDATA"]) {
		[self showSyncMessage:YES];
		NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CREDENTIALS"];
		[[parser shared] setDelegate:self];
		[[parser shared] parse:OBTERTRANSACTIONS withParam:[NSDictionary dictionaryWithObjectsAndKeys:TRANSACTIONS, @"url", [dict objectForKey:@"KEY"], @"key", nil]];
		dict = nil;
	}

	if ([[notification name] isEqualToString:@"SYNCHRONIZE"]) {
		[self synchronizeData];
	}

	if ([[notification name] isEqualToString:@"ABORTSYNC"]) {
		[[parser shared] abortLibXMLParse];
		abortSync = YES;

		[UIView animateWithDuration:0.4
							  delay:3.0
							options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionNone
						 animations:^{[self.tooltipView setAlpha:0];}
						 completion:^(BOOL finished){[self.tooltipView setHidden:YES];}];

		[self.noDataView setHidden:([[self.fetchedResultsController sections] count] > 0)];
	}

	if ([[notification name] isEqualToString:@"NONETWORKNOTIFICATION"]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"NONETWORKNOTIFICATION" object:nil];
		[self.noDataView setHidden:([[self.fetchedResultsController sections] count] > 0)];
	}
}

#pragma mark - parser Delegate methods

- (void)showNoNetworkErrorMessage {
	[self showSyncMessage:NO];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackNotifications:) name:@"NONETWORKNOTIFICATION" object:nil];
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkMessageWithCancelButton:YES];

	[UIView animateWithDuration:0.4
						  delay:3.0
						options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionNone
					 animations:^{[self.tooltipView setAlpha:0];}
					 completion:^(BOOL finished){[self.tooltipView setHidden:YES];}];
}

- (void)showNetworkErrorMessage {
	[self showSyncMessage:NO];
	[UIView animateWithDuration:0.4
						  delay:3.0
						options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionNone
					 animations:^{[self.tooltipView setAlpha:0];}
					 completion:^(BOOL finished){[self.tooltipView setHidden:YES];}];
}

- (void)showErrorMessage {
	[self showSyncMessage:NO];
	[UIView animateWithDuration:0.4
						  delay:3.0
						options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionNone
					 animations:^{[self.tooltipView setAlpha:0];}
					 completion:^(BOOL finished){[self.tooltipView setHidden:YES];}];
}

- (void)returnFromParse:(id)parsedObject withData:(NSData *)parsedData {
	id response = [NSKeyedUnarchiver unarchiveObjectWithData:parsedData];
	if ([response isKindOfClass:[NSArray class]]) {
		switch ([(parser *)parsedObject whatToDo]) {

			case OBTERTRANSACTIONS: {
				NSMutableArray *responseArray = [NSMutableArray arrayWithArray:(NSArray *)response];
				if ([responseArray count] > 0) {
					// Get existing data
					NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
					[fetchRequest setEntity:[NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.managedObjectContext]];
					[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uuid IN %@", [responseArray valueForKey:@"uuid"]]];
					
					// Delete all matched data
					NSArray *transactionsObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
					for (NSManagedObject *object in transactionsObject) {
						[self.managedObjectContext deleteObject:object];
					}
					transactionsObject = nil;
					
					[fetchRequest release]; fetchRequest = nil;
					
					// Save data to CORE DATA
					for (NSDictionary *dict in responseArray) {
						NSManagedObject *transactions = [NSEntityDescription insertNewObjectForEntityForName:@"Transactions" inManagedObjectContext:self.managedObjectContext];
						[transactions setValue:([dict objectForKey:@"recurrence_uuid"] == nil ? @"" : [dict objectForKey:@"recurrence_uuid"]) forKey:@"recurrence_uuid"];
						[transactions setValue:[dict objectForKey:@"uuid"] forKey:@"uuid"];

						[transactions setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"id"] integerValue]] forKey:@"id"];
						[transactions setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"repeat_finder"] integerValue]] forKey:@"repeat_finder"];
						[transactions setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"account_id"] integerValue]] forKey:@"account_id"];
						[transactions setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"tag_id"] integerValue]] forKey:@"tag_id"];
						[transactions setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"transfer_id"] integerValue]] forKey:@"transfer_id"];
						[transactions setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"transfer_from"] integerValue]] forKey:@"transfer_from"];
						[transactions setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"transfer_to"] integerValue]] forKey:@"transfer_to"];

						[transactions setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"created_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"created_at"];
						[transactions setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"updated_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"updated_at"];
						[transactions setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"deleted_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"deleted_at"];

						[transactions setValue:[NSNumber numberWithBool:[[dict objectForKey:@"done"] boolValue]] forKey:@"done"];
						[transactions setValue:[NSNumber numberWithBool:[[dict objectForKey:@"income"] boolValue]] forKey:@"income"];
						[transactions setValue:[NSNumber numberWithBool:[[dict objectForKey:@"start_result"] boolValue]] forKey:@"start_result"];
						[transactions setValue:[NSNumber numberWithBool:[[dict objectForKey:@"transfer"] boolValue]] forKey:@"transfer"];

						[transactions setValue:[dict objectForKey:@"date"] forKey:@"date"];
						[transactions setValue:[[dict objectForKey:@"description_text"] description] forKey:@"description_text"];
						[transactions setValue:[dict objectForKey:@"user_id"] forKey:@"user_id"];
						[transactions setValue:[dict objectForKey:@"observation"] forKey:@"observation"];
						[transactions setValue:[dict objectForKey:@"repeat_index"] forKey:@"repeat_index"];
						[transactions setValue:[dict objectForKey:@"repeat_type"] forKey:@"repeat_type"];
						[transactions setValue:[dict objectForKey:@"repeat_total"] forKey:@"repeat_total"];

						[transactions setValue:[NSNumber numberWithBool:YES] forKey:@"synced"];

						NSDecimalNumber *amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:@"0"];
						if (![[dict objectForKey:@"ammount"] isEqualToString:@""]) {
							amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:[dict objectForKey:@"ammount"]];
						}
						[transactions setValue:amount forKey:@"ammount"];
						amount = nil;

						transactions = nil;
					}

					// Save the context.
					NSError *error = nil;
					if (![self.managedObjectContext save:&error]) {
						// Replace this implementation with code to handle the error appropriately.
						NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
					}

				}

				[[parser shared] setDelegate:nil];
				[[parser shared] destroy];

				NSDictionary *syncMessage = [NSDictionary dictionaryWithObjectsAndKeys:
											 @"Sincronização Concluída", @"title", 
											 @"Seus dados foram sincronizados!", @"message", 
											 [NSNumber numberWithBool:NO], @"showArrow", 
											 [NSNumber numberWithBool:NO], @"showCancel", nil];
				[(AppDelegate *)[[UIApplication sharedApplication] delegate] showSyncMessage:YES withMessages:syncMessage];
				syncMessage = nil;
				
				[UIView animateWithDuration:0.4f
								 animations:^{
									 [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.view cache:NO];
									 [self.noDataView setHidden:([[self.fetchedResultsController sections] count] > 0)];
								 }
				 ];

				[self performSelectorInBackground:@selector(sleepAndExit) withObject:nil];

				responseArray = nil;
				[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LASTSYNC"];
			} break;

			case DOSYNC: {
				NSMutableArray *responseArray = [NSMutableArray arrayWithArray:(NSArray *)response];
				if ([responseArray count] > 0) {
					NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"entity" ascending:YES] autorelease];
					[responseArray sortUsingDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
					sortDescriptor = nil;

					// Save data to CORE DATA					
					for (NSDictionary *dict in responseArray) {
						if ([[dict objectForKey:@"entity"] isEqualToString:@"Tags"]) {
							NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
							[fetchRequest setEntity:[NSEntityDescription entityForName:@"Tags" inManagedObjectContext:self.managedObjectContext]];
							[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"id == %d", [[dict objectForKey:@"id"] integerValue]]];
							
							NSArray *tagsObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
							NSManagedObject *tags = nil;
							
							if ([tagsObject count] == 0) {
								tags = [NSEntityDescription insertNewObjectForEntityForName:@"Tags" inManagedObjectContext:self.managedObjectContext];
								[tags setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"id"] integerValue]] forKey:@"id"];
							} else {
								tags = [tagsObject objectAtIndex:0];
							}
							
							[tags setValue:[NSNumber numberWithBool:[[dict objectForKey:@"none"] boolValue]] forKey:@"none"];
							[tags setValue:[NSNumber numberWithBool:[[dict objectForKey:@"permanent"] boolValue]] forKey:@"permanent"];
							[tags setValue:[NSNumber numberWithBool:[[dict objectForKey:@"translate"] boolValue]] forKey:@"translate"];
							[tags setValue:[dict objectForKey:@"color"] forKey:@"color"];
							[tags setValue:[dict objectForKey:@"user_id"] forKey:@"user_id"];
							[tags setValue:[dict objectForKey:@"name"] forKey:@"name"];
							
							NSDecimalNumber *amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:@"0"];
							if (![[dict objectForKey:@"montly_ammount"] isEqualToString:@""]) {
								amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:[dict objectForKey:@"montly_ammount"]];
							}
							[tags setValue:amount forKey:@"montly_ammount"];
							amount = nil;
							
							[tags setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"parent_id"] integerValue]] forKey:@"parent_id"];
							
							[tags setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"created_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"created_at"];
							[tags setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"updated_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"updated_at"];
							[tags setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"deleted_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"deleted_at"];

							tags = nil; tagsObject = nil;
							[fetchRequest release]; fetchRequest = nil;
						}

						if ([[dict objectForKey:@"entity"] isEqualToString:@"Accounts"]) {
							NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
							[fetchRequest setEntity:[NSEntityDescription entityForName:@"Accounts" inManagedObjectContext:self.managedObjectContext]];
							[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"id == %d", [[dict objectForKey:@"id"] integerValue]]];

							NSArray *accountObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
							NSManagedObject *object = nil;
							
							if ([accountObject count] == 0) {
								object = [NSEntityDescription insertNewObjectForEntityForName:@"Accounts" inManagedObjectContext:self.managedObjectContext];
								[object setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"id"] integerValue]] forKey:@"id"];
							} else {
								object = [accountObject objectAtIndex:0];
							}

							[object setValue:[NSNumber numberWithBool:[[dict objectForKey:@"none"] boolValue]] forKey:@"none"];
							[object setValue:[dict objectForKey:@"flag"] forKey:@"flag"];
							[object setValue:[dict objectForKey:@"flag_icon"] forKey:@"flag_icon"];
							[object setValue:[dict objectForKey:@"icon"] forKey:@"icon"];
							[object setValue:[dict objectForKey:@"kind"] forKey:@"kind"];
							[object setValue:[dict objectForKey:@"user_id"] forKey:@"user_id"];
							[object setValue:[dict objectForKey:@"name"] forKey:@"name"];
							[object setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"created_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"created_at"];
							[object setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"updated_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"updated_at"];
							[object setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"deleted_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"deleted_at"];

							object = nil; accountObject = nil;
							[fetchRequest release]; fetchRequest = nil;
						}

						if ([[dict objectForKey:@"entity"] isEqualToString:@"User_Config"]) {
							for (NSDictionary *dict in responseArray) {
								NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
								[fetchRequest setEntity:[NSEntityDescription entityForName:@"User_Config" inManagedObjectContext:self.managedObjectContext]];
								
								NSArray *accountObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
								NSManagedObject *object = nil;
								
								if ([accountObject count] == 0) {
									object = [NSEntityDescription insertNewObjectForEntityForName:@"User_Config" inManagedObjectContext:self.managedObjectContext];
								} else {
									object = [accountObject objectAtIndex:0];
								}
								
								[object setValue:[NSNumber numberWithBool:[[dict objectForKey:@"transactions_consider_only_done_outcomes"] boolValue]] forKey:@"transactions_consider_only_done_outcomes"];
								[object setValue:[NSNumber numberWithBool:[[dict objectForKey:@"transactions_consider_only_done_incomes"] boolValue]] forKey:@"transactions_consider_only_done_incomes"];
								[object setValue:[NSNumber numberWithBool:[[dict objectForKey:@"transactions_transfer_result"] boolValue]] forKey:@"transactions_transfer_result"];
								[object setValue:[NSNumber numberWithBool:[[dict objectForKey:@"transactions_set_done"] boolValue]] forKey:@"transactions_set_done"];
								[object setValue:[dict objectForKey:@"transactions_transfer_result_start_month"] forKey:@"transactions_transfer_result_start_month"];
								[object setValue:[dict objectForKey:@"versao_mais"] forKey:@"versao_mais"];
								object = nil;

								NSDictionary *credentialDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CREDENTIALS"];
								[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:
																				  [credentialDict objectForKey:@"USUARIO"], @"USUARIO", 
																				  [credentialDict objectForKey:@"SENHA"], @"SENHA", 
																				  [credentialDict objectForKey:@"KEY"], @"KEY", 
																				  [dict objectForKey:@"transactions_transfer_result_start_month"], @"TRANSFER_MONTH",
																				  [dict objectForKey:@"transactions_transfer_result"], @"TRANSFER", 
																				  nil]
																		  forKey:@"CREDENTIALS"];
								credentialDict = nil;
								[fetchRequest release]; fetchRequest = nil;
							}
						}

						if ([[dict objectForKey:@"entity"] isEqualToString:@"Transactions"]) {
							if ([[dict objectForKey:@"sync_status"] isEqualToString:@"ok"]) {
								NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
								[fetchRequest setEntity:[NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.managedObjectContext]];
								[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", [dict objectForKey:@"uuid"]]];
								
								NSArray *transactionsObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
								
								if ([transactionsObject count] == 0) {
									[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"mobile_record_id == %d", [[dict objectForKey:@"mobile_record_id"] integerValue]]];
									transactionsObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
									if ([transactionsObject count] > 0) {
										NSManagedObject *object = [transactionsObject objectAtIndex:0];
										[object setValue:[NSNumber numberWithBool:YES] forKey:@"synced"];
										object = nil;
									}
								} else {
									NSManagedObject *object = [transactionsObject objectAtIndex:0];
									[object setValue:[NSNumber numberWithBool:YES] forKey:@"synced"];
									object = nil;
								}
								transactionsObject = nil;
								[fetchRequest release]; fetchRequest = nil;
							}

							if ([[dict objectForKey:@"sync_status"] isEqualToString:@"update"]) {
								NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
								[fetchRequest setEntity:[NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.managedObjectContext]];
								[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", [dict objectForKey:@"uuid"]]];
								
								NSArray *transactionsObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
								NSManagedObject *object = nil;
								BOOL createNewObject = NO;
								
								if ([transactionsObject count] == 0) {
									if (![[dict objectForKey:@"mobile_record_id"] isEqualToString:@""]) {
										[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"mobile_record_id == %d", [[dict objectForKey:@"mobile_record_id"] integerValue]]];
										transactionsObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
										
										if ([transactionsObject count] == 0) {
											createNewObject = YES;
										}
									} else {
										createNewObject = YES;
									}
								}
								
								if (createNewObject) {
									object = [NSEntityDescription insertNewObjectForEntityForName:@"Transactions" inManagedObjectContext:self.managedObjectContext];
								} else {
									object = [transactionsObject objectAtIndex:0];
								}
								
								[object setValue:[dict objectForKey:@"uuid"] forKey:@"uuid"];

								[object setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"repeat_finder"] integerValue]] forKey:@"repeat_finder"];
								[object setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"account_id"] integerValue]] forKey:@"account_id"];
								[object setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"tag_id"] integerValue]] forKey:@"tag_id"];
								[object setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"transfer_id"] integerValue]] forKey:@"transfer_id"];
								[object setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"transfer_from"] integerValue]] forKey:@"transfer_from"];
								[object setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"transfer_to"] integerValue]] forKey:@"transfer_to"];
								
								[object setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"created_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"created_at"];
								[object setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"updated_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"updated_at"];
								[object setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"deleted_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"deleted_at"];
								
								[object setValue:[NSNumber numberWithBool:[[dict objectForKey:@"done"] boolValue]] forKey:@"done"];
								[object setValue:[NSNumber numberWithBool:[[dict objectForKey:@"income"] boolValue]] forKey:@"income"];
								[object setValue:[NSNumber numberWithBool:[[dict objectForKey:@"start_result"] boolValue]] forKey:@"start_result"];
								[object setValue:[NSNumber numberWithBool:[[dict objectForKey:@"transfer"] boolValue]] forKey:@"transfer"];
								
								[object setValue:[NSNumber numberWithBool:YES] forKey:@"synced"];
								
								[object setValue:[dict objectForKey:@"date"] forKey:@"date"];
								[object setValue:[[dict objectForKey:@"description_text"] description] forKey:@"description_text"];
								[object setValue:[dict objectForKey:@"user_id"] forKey:@"user_id"];
								[object setValue:[dict objectForKey:@"observation"] forKey:@"observation"];
								[object setValue:[dict objectForKey:@"repeat_index"] forKey:@"repeat_index"];
								[object setValue:[dict objectForKey:@"repeat_type"] forKey:@"repeat_type"];
								[object setValue:[dict objectForKey:@"repeat_total"] forKey:@"repeat_total"];
								[object setValue:([dict objectForKey:@"recurrence_uuid"] == nil ? @"" : [dict objectForKey:@"recurrence_uuid"]) forKey:@"recurrence_uuid"];
								
								NSDecimalNumber *amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:@"0"];
								if (![[dict objectForKey:@"ammount"] isEqualToString:@""]) {
									amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:[dict objectForKey:@"ammount"]];
								}
								[object setValue:amount forKey:@"ammount"];
								amount = nil;
								
								object = nil; transactionsObject = nil;
								[fetchRequest release]; fetchRequest = nil;
							}
						}
					}

					// Save the context.
					NSError *error = nil;
					if (![self.managedObjectContext save:&error]) {
						// Replace this implementation with code to handle the error appropriately.
						NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
					}
				}

				responseArray = nil;

				NSDictionary *syncMessage = [NSDictionary dictionaryWithObjectsAndKeys:
											 @"Sincronização Concluída", @"title", 
											 @"Seus dados foram sincronizados!", @"message", 
											 [NSNumber numberWithBool:NO], @"showArrow", 
											 [NSNumber numberWithBool:NO], @"showCancel", nil];
				[(AppDelegate *)[[UIApplication sharedApplication] delegate] showSyncMessage:YES withMessages:syncMessage];
				syncMessage = nil;

				[UIView animateWithDuration:0.4f
								 animations:^{
									 [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.view cache:NO];
									 [self.noDataView setHidden:([[self.fetchedResultsController sections] count] > 0)];
								 }
				 ];

				[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LASTSYNC"];

				NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CREDENTIALS"];
				[[parser shared] parse:DOSYNCDONE withParam:[NSDictionary dictionaryWithObjectsAndKeys:SYNCDONE, @"url", [dict objectForKey:@"KEY"], @"key", nil]];
				dict = nil;

				[self performSelectorInBackground:@selector(sleepAndExit) withObject:nil];
			} break;

			default: {
			}	break;
		}

	} else if ([response isKindOfClass:[NSString class]]) {
		[self showSyncMessage:NO];

		[[parser shared] setDelegate:nil];
		[[parser shared] destroy];
	}
	response = nil;

	// Apagar arquivo de sync
	[[NSFileManager defaultManager] removeItemAtPath:[[sharedMethods shared] getFilename:@"body"] error:NULL];

	[UIView animateWithDuration:0.4
						  delay:3.0
						options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionNone
					 animations:^{[self.tooltipView setAlpha:0];}
					 completion:^(BOOL finished){[self.tooltipView setHidden:YES];}];
}

#pragma mark - Touch Events

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = touches.anyObject;
	if (touch.view == self.detailsView || touch.view == self.resumeView || touch.view == self.previousView) {
		[self showHideDetailView];
	}
	touch = nil;
}

#pragma mark - View Methods

- (void)sleepAndExit {
	[NSThread sleepForTimeInterval:1.2];
	[self performSelectorOnMainThread:@selector(exit) withObject:nil waitUntilDone:NO];
	[NSThread exit];
}

- (void)exit {
	[self showSyncMessage:NO];
	[self updateDetailView];
}

- (void)showSyncMessage:(BOOL)show {
	if (show) {
		NSDictionary *syncMessage = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Sincronizando", @"title", 
									 @"Isso pode levar algum tempo.", @"message", 
									 [NSNumber numberWithBool:YES], @"showArrow", 
									 [NSNumber numberWithBool:YES], @"showCancel", nil];
		[(AppDelegate *)[[UIApplication sharedApplication] delegate] showSyncMessage:YES withMessages:syncMessage];
		syncMessage = nil;
		
	} else {
		[(AppDelegate *)[[UIApplication sharedApplication] delegate] showSyncMessage:NO withMessages:nil];
	}
}

- (void)showConfig {
	[UIView animateWithDuration:0.4
						  delay:3.0
						options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionNone
					 animations:^{[self.tooltipView setAlpha:0];}
					 completion:^(BOOL finished){[self.tooltipView setHidden:YES];}];

    Configuracoes_TableViewController *configViewController = [[Configuracoes_TableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:configViewController animated:YES];
    [configViewController release]; configViewController = nil;
}

- (void)synchronizeData {
	[self showSyncMessage:YES];
	abortSync = NO;

	NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"LASTSYNC"];
	if (lastSyncDate == nil) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"GETNEWDATA" object:nil];
	} else {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSString *lastSync = [[sharedMethods shared] formattedStringFromDate:lastSyncDate usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"];
			lastSync = [NSString stringWithFormat:@"%@:%@", [lastSync substringToIndex:[lastSync length] - 2], [lastSync substringFromIndex:[lastSync length] - 2]];
			NSString *body = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><synchronization><transactions>";

			NSEntityDescription *entity = [NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.managedObjectContext];
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			[fetchRequest setEntity:entity];
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"synced == %@", [NSNumber numberWithBool:NO]]];

			[[sharedMethods shared] saveFile:@"body" withData:[body dataUsingEncoding:NSUTF8StringEncoding] appendContent:NO];

			for (NSManagedObject *managedObject in [self.managedObjectContext executeFetchRequest:fetchRequest error:nil]) {
				if (abortSync) break;

				body = nil; body = @"";
				body = [body stringByAppendingString:@"<transaction>"];

				NSDictionary *attributes = [entity attributesByName];
				for (NSString *key in [attributes allKeys]) {
					NSString *xmlKey = [key stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
					NSString *keyToReplace = @"-text";
					NSRange range = [xmlKey rangeOfString:keyToReplace options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
					if (range.location != NSNotFound) {
						xmlKey = [xmlKey substringToIndex:([xmlKey length] - [keyToReplace length])];
					}
					keyToReplace = nil;

					NSString *myValue = [[managedObject valueForKey:key] description];
					NSAttributeDescription *myAttribute = [attributes objectForKey:key];
					if ([myAttribute attributeType] == NSDateAttributeType) {
						if (myValue != nil) {
							myValue = [[sharedMethods shared] formattedStringFromDate:[managedObject valueForKey:key] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"];
							myValue = [NSString stringWithFormat:@"%@:%@", [myValue substringToIndex:[lastSync length] - 3], [myValue substringFromIndex:[lastSync length] - 3]];
						}
					} else if ([myAttribute attributeType] == NSBooleanAttributeType) {
						myValue = ([[managedObject valueForKey:key] boolValue] ? @"true" : @"false");
					}
					if (![key isEqualToString:@"synced"]) {
						body = [body stringByAppendingFormat:@"<%@>%@</%@>", xmlKey, (myValue == nil ? @"" : myValue), xmlKey];
					}
					xmlKey = nil; myValue = nil; myAttribute = nil;
				}
				attributes = nil;
				body = [body stringByAppendingString:@"</transaction>"];

				[[sharedMethods shared] saveFile:@"body" withData:[body dataUsingEncoding:NSUTF8StringEncoding] appendContent:YES];
			}
			lastSync = nil;
			[fetchRequest release]; fetchRequest = nil;

			body = nil; body = @"";
			body = [body stringByAppendingString:@"</transactions>"];
			body = [body stringByAppendingFormat:@"<device-id>%@</device-id>", [[sharedMethods shared] getMyUDID]];
			body = [body stringByAppendingString:@"</synchronization>"];

			[[sharedMethods shared] saveFile:@"body" withData:[body dataUsingEncoding:NSUTF8StringEncoding] appendContent:YES];
			body = nil;

			dispatch_async(dispatch_get_main_queue(), ^{
				if (!abortSync) {
					NSString *theBody = [NSString stringWithContentsOfFile:[[sharedMethods shared] getFilename:@"body"] encoding:NSUTF8StringEncoding error:nil];
					if (theBody != nil) {
						NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CREDENTIALS"];
						[[parser shared] setDelegate:self];
						[[parser shared] parse:DOSYNC withParam:[NSDictionary dictionaryWithObjectsAndKeys:SYNC, @"url", [dict objectForKey:@"KEY"], @"key", theBody, @"body", nil]];
						dict = nil;
					}
					theBody = nil; 
				}
			});
		});
	}
	lastSyncDate = nil;
}

- (void)setNewDate {
	NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:[NSDate date]];
	[components setMonth:([components month] + months)];
	NSDate *newDate = [[NSCalendar currentCalendar] dateFromComponents:components];
	components = nil;

	self.currentMonth = [[sharedMethods shared] formattedStringFromDate:newDate usingFormat:@"yyyy-MM"];
	[self.headerLabel setText:[NSString stringWithFormat:@"%@ de %@", [[[sharedMethods shared] formattedStringFromDate:newDate usingFormat:@"MMMM"] capitalizedString], [[sharedMethods shared] formattedStringFromDate:newDate usingFormat:@"yyyy"]]];
	
	newDate = nil;
}

- (IBAction)previousMonth:(id)sender {
	[UIView animateWithDuration:0.4
						  delay:3.0
						options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionNone
					 animations:^{[self.tooltipView setAlpha:0];}
					 completion:^(BOOL finished){[self.tooltipView setHidden:YES];}];

	[self moveToPreviousItem];
}

- (void)moveToPreviousItem {
	months--;
	[self setNewDate];

	self.fetchedResultsController = nil;
	downOrientation = YES;
	
	[UIView animateWithDuration:0.4f
					 animations:^{
						 [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.view cache:NO];
						 [self.tableView reloadData];
					 }
	 ];

	[self updateDetailView];
	if ([[self.fetchedResultsController sections] count] > 0) {
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}
}

- (IBAction)nextMonth:(id)sender {
	[UIView animateWithDuration:0.4
						  delay:3.0
						options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionNone
					 animations:^{[self.tooltipView setAlpha:0];}
					 completion:^(BOOL finished){[self.tooltipView setHidden:YES];}];

	[self moveToNextItem];
}

- (void)moveToNextItem {
	months++;
	[self setNewDate];

	self.fetchedResultsController = nil;
	downOrientation = NO;
	
	[UIView animateWithDuration:0.4f
					 animations:^{
						 [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.view cache:NO];
						 [self.tableView reloadData];
					 }
	 ];

	[self updateDetailView];
	if ([[self.fetchedResultsController sections] count] > 0) {
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}
}

- (void)updateDetailView {
	BOOL transactions_consider_only_done_outcomes = NO;
	BOOL transactions_consider_only_done_incomes = NO;

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"User_Config" inManagedObjectContext:self.managedObjectContext]];

	for (NSManagedObject *object in [self.managedObjectContext executeFetchRequest:fetchRequest error:nil]) {
		transactions_consider_only_done_outcomes = [[object valueForKey:@"transactions_consider_only_done_outcomes"] boolValue];
		transactions_consider_only_done_incomes = [[object valueForKey:@"transactions_consider_only_done_incomes"] boolValue];
	}

	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.managedObjectContext]];

	NSMutableArray *predicate = [NSMutableArray arrayWithObjects:
								 [NSPredicate predicateWithFormat:@"start_result == 0"],
								 [NSPredicate predicateWithFormat:@"transfer == 0"],
								 [NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]],
								 [NSPredicate predicateWithFormat:@"income == 1"], 
								 [NSPredicate predicateWithFormat:@"date BEGINSWITH %@", self.currentMonth], 
								 nil];
	if (transactions_consider_only_done_incomes) {
		[predicate addObject:[NSPredicate predicateWithFormat:@"done == 1"]];
	}

	[fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicate]];
	predicate = nil;

	NSArray *income = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	NSDecimalNumber *incomeSum = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithDecimal:[[income valueForKeyPath:@"@sum.ammount"] decimalValue]];
	[self.incomeLabel setText:[[sharedMethods shared] currencyFormat:[NSString stringWithFormat:@"%@", incomeSum] usingSymbol:@"R$ " andDigits:2]];
	[self.incomeLabel setTextColor:GREENCOLOR];

	predicate = [NSMutableArray arrayWithObjects:
				 [NSPredicate predicateWithFormat:@"start_result == 0"],
				 [NSPredicate predicateWithFormat:@"transfer == 0"],
				 [NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]],
				 [NSPredicate predicateWithFormat:@"income == 0"], 
				 [NSPredicate predicateWithFormat:@"date BEGINSWITH %@", self.currentMonth], 
				 nil];
	if (transactions_consider_only_done_outcomes) {
		[predicate addObject:[NSPredicate predicateWithFormat:@"done == 1"]];
	}
	
	[fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicate]];
	predicate = nil;

	NSArray *expense = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	NSDecimalNumber *expenseSum = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithDecimal:[[expense valueForKeyPath:@"@sum.ammount"] decimalValue]];
	[self.expenseLabel setText:[[sharedMethods shared] currencyFormat:[NSString stringWithFormat:@"%@", expenseSum] usingSymbol:@"R$ " andDigits:2]];
	[self.expenseLabel setTextColor:REDCOLOR];

	NSDecimalNumber *currentAmmount = (NSDecimalNumber *)[incomeSum decimalNumberBySubtracting:expenseSum];

	if (self.detailsView.frame.origin.y < self.view.frame.size.height) {
		[self showHideDetailView];
		[self showHideDetailView];
	}

	NSDecimalNumber *initialAmmount = [self getInitialAmmount];
	NSDecimalNumber *previousAmmount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:@"0"];
	NSDictionary *dict  = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CREDENTIALS"];
	if ([[dict objectForKey:@"TRANSFER"] boolValue]) {
		predicate = [NSMutableArray arrayWithObjects:
					 [NSPredicate predicateWithFormat:@"transfer == 0"],
					 [NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]],
					 [NSPredicate predicateWithFormat:@"income == 1"], 
					 nil];
		if (transactions_consider_only_done_incomes) {
			[predicate addObject:[NSPredicate predicateWithFormat:@"done == 1"]];
		}
		if ([dict objectForKey:@"TRANSFER_MONTH"] != nil) {
			[predicate addObject:[NSPredicate predicateWithFormat:@"date >= %@ AND date < %@", [dict objectForKey:@"TRANSFER_MONTH"], [[sharedMethods shared] formattedStringFromString:self.currentMonth withFormat:@"yyyy-MM" andDisplayFormat:@"yyyy-MM-dd"]]];
		}
		
		[fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicate]];
		predicate = nil;
		
		income = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
		incomeSum = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithDecimal:[[income valueForKeyPath:@"@sum.ammount"] decimalValue]];

		predicate = [NSMutableArray arrayWithObjects:
					 [NSPredicate predicateWithFormat:@"transfer == 0"],
					 [NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]],
					 [NSPredicate predicateWithFormat:@"income == 0"], 
					 nil];
		if (transactions_consider_only_done_outcomes) {
			[predicate addObject:[NSPredicate predicateWithFormat:@"done == 1"]];
		}
		if ([dict objectForKey:@"TRANSFER_MONTH"] != nil) {
			[predicate addObject:[NSPredicate predicateWithFormat:@"date >= %@ AND date < %@", [dict objectForKey:@"TRANSFER_MONTH"], [[sharedMethods shared] formattedStringFromString:self.currentMonth withFormat:@"yyyy-MM" andDisplayFormat:@"yyyy-MM-dd"]]];
		}
		
		[fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicate]];
		predicate = nil;
		
		expense = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
		expenseSum = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithDecimal:[[expense valueForKeyPath:@"@sum.ammount"] decimalValue]];

		previousAmmount = (NSDecimalNumber *)[incomeSum decimalNumberBySubtracting:expenseSum];
	}

	NSString *saldo = @"Saldo Anterior";
	if (fabs([initialAmmount floatValue]) > 0) {
		saldo = @"Saldo Inicial";
		if (fabs([previousAmmount floatValue]) > 0) {
			saldo = @"Saldos";
		}
	}

	[self.saldoInicial setText:saldo];
	saldo = nil;

	previousAmmount = (NSDecimalNumber *)[previousAmmount decimalNumberByAdding:initialAmmount];

	[self.previousLabel setText:[[sharedMethods shared] currencyFormat:[NSString stringWithFormat:@"%@", previousAmmount] usingSymbol:@"R$ " andDigits:2]];
	[self.previousLabel setTextColor:([previousAmmount compare:(NSDecimalNumber *)[NSDecimalNumber zero]] == NSOrderedAscending ? REDCOLOR : GREENCOLOR)];
	
	[self.footerLabel setText:[[sharedMethods shared] currencyFormat:[NSString stringWithFormat:@"%@", [previousAmmount decimalNumberByAdding:currentAmmount]] usingSymbol:@"R$ " andDigits:2]];
	[self.footerLabel setTextColor:([[previousAmmount decimalNumberByAdding:currentAmmount] compare:(NSDecimalNumber *)[NSDecimalNumber zero]] == NSOrderedAscending ? REDCOLOR : GREENCOLOR)];

	previousAmmount = nil;
	dict = nil;

	currentAmmount = nil;
	expenseSum = nil; expense = nil;
	incomeSum = nil; income = nil;
	[fetchRequest release]; fetchRequest = nil;
}

- (NSDecimalNumber *)getInitialAmmount {
	BOOL transactions_consider_only_done_outcomes = NO;
	BOOL transactions_consider_only_done_incomes = NO;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"User_Config" inManagedObjectContext:self.managedObjectContext]];
	
	for (NSManagedObject *object in [self.managedObjectContext executeFetchRequest:fetchRequest error:nil]) {
		transactions_consider_only_done_outcomes = [[object valueForKey:@"transactions_consider_only_done_outcomes"] boolValue];
		transactions_consider_only_done_incomes = [[object valueForKey:@"transactions_consider_only_done_incomes"] boolValue];
	}
	
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.managedObjectContext]];
	
	NSMutableArray *predicate = [NSMutableArray arrayWithObjects:
								 [NSPredicate predicateWithFormat:@"start_result == 1"],
								 [NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]],
								 [NSPredicate predicateWithFormat:@"income == 1"], 
								 [NSPredicate predicateWithFormat:@"date BEGINSWITH %@", self.currentMonth], 
								 nil];
	if (transactions_consider_only_done_incomes) {
		[predicate addObject:[NSPredicate predicateWithFormat:@"done == 1"]];
	}
	
	[fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicate]];
	predicate = nil;

	NSArray *income = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	NSDecimalNumber *incomeSum = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithDecimal:[[income valueForKeyPath:@"@sum.ammount"] decimalValue]];

	predicate = [NSMutableArray arrayWithObjects:
				 [NSPredicate predicateWithFormat:@"start_result == 1"],
				 [NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]],
				 [NSPredicate predicateWithFormat:@"income == 0"], 
				 [NSPredicate predicateWithFormat:@"date BEGINSWITH %@", self.currentMonth], 
				 nil];
	if (transactions_consider_only_done_outcomes) {
		[predicate addObject:[NSPredicate predicateWithFormat:@"done == 1"]];
	}
	
	[fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicate]];
	predicate = nil;

	NSArray *expense = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	NSDecimalNumber *initialAmmount = (NSDecimalNumber *)[incomeSum decimalNumberBySubtracting:(NSDecimalNumber *)[NSDecimalNumber decimalNumberWithDecimal:[[expense valueForKeyPath:@"@sum.ammount"] decimalValue]]];

	expense = nil; incomeSum = nil; income = nil;
	[fetchRequest release]; fetchRequest = nil;

	return initialAmmount;
}

- (void)showHideDetailView {
	int toolbarHeight = 43;
	int resumeHeight = 42;
	int detailHeight = 42;

	CGRect detailRect = self.detailsView.frame;
	detailRect.origin.y = (detailRect.origin.y == self.view.frame.size.height ? self.view.frame.size.height - (detailHeight + resumeHeight) : self.view.frame.size.height);

	NSDictionary *dict  = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CREDENTIALS"];
	NSDate *transfer = [[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"TRANSFER_MONTH"] usingFormat:@"yyyy-MM-dd"];
	NSDate *current = [[sharedMethods shared] dateFromFormattedString:self.currentMonth usingFormat:@"yyyy-MM"];
	NSDecimalNumber *initialAmmount = [self getInitialAmmount];
	int previousHeight = (([[dict objectForKey:@"TRANSFER"] boolValue] && [transfer earlierDate:current] == transfer) || [initialAmmount doubleValue] != 0 ? 26 : 0);
	initialAmmount = nil; current = nil; transfer = nil; dict = nil;

	CGRect previousRect = self.previousView.frame;
	previousRect.origin.y = (detailRect.origin.y == self.view.frame.size.height ? self.view.frame.size.height : self.view.frame.size.height - (detailHeight + resumeHeight + previousHeight));
	[self.previousView setHidden:(previousHeight == 0)];

	CGRect resumeRect = self.resumeView.frame;
	resumeRect.size.height = (detailRect.origin.y == self.view.frame.size.height ? resumeHeight : resumeHeight + detailHeight + previousHeight);
	resumeRect.origin.y = self.view.frame.size.height - resumeRect.size.height;
	
	CGRect tableRect = self.tableView.frame;
	tableRect.size.height = (detailRect.origin.y == self.view.frame.size.height ? self.view.frame.size.height - (resumeHeight + toolbarHeight) : self.view.frame.size.height - (detailHeight + resumeHeight + previousHeight + toolbarHeight));

	[UIView beginAnimations:@"move" context:NULL];
	[UIView setAnimationDuration:0.3f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationWillStartSelector:@selector(fadeOff)];
	[UIView setAnimationDidStopSelector:@selector(fadeOn)];
	self.arrow.transform = CGAffineTransformRotate(self.arrow.transform, -M_PI);
	self.detailsView.frame = detailRect;
	self.previousView.frame = previousRect;
	self.tableView.frame = tableRect;
	self.resumeView.frame = resumeRect;
	[UIView commitAnimations];
}

- (void)fadeOff {
	[UIView animateWithDuration:0.1f
					 animations:^{
						 self.detailsView.alpha = 0;
						 self.previousView.alpha = 0;
					 }
	 ];
}

- (void)fadeOn {
	[UIView animateWithDuration:0.2f
					 animations:^{
						 self.detailsView.alpha = (self.detailsView.frame.origin.y == self.view.frame.size.height ? 0 : 1);
						 self.previousView.alpha = (self.detailsView.frame.origin.y == self.view.frame.size.height ? 0 : 1);
					 }
	 ];
}

- (void)addRecord:(id)sender {
	[UIView animateWithDuration:0.4
						  delay:3.0
						options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionNone
					 animations:^{[self.tooltipView setAlpha:0];}
					 completion:^(BOOL finished){[self.tooltipView setHidden:YES];}];

	NSManagedObject *object = nil;

	if ([sender isKindOfClass:[NSManagedObject class]]) {
		object = (NSManagedObject *)sender;
	}

	AddMovimento_TableViewController *anotherViewController = [[[AddMovimento_TableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	[anotherViewController setTransaction:object];
	[anotherViewController setCurrentMonth:self.currentMonth];

	UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:anotherViewController] autorelease];
	[navigationController setDelegate:(AppDelegate *)[[UIApplication sharedApplication] delegate]];
    [self.navigationController presentModalViewController:navigationController animated:YES];
	anotherViewController = nil; navigationController = nil;
}

@end
