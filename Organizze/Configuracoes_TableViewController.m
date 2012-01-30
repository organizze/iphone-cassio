//
//  Configuracoes_TableViewController.m
//  Organizze
//
//  Created by Cassio Rossi on 11/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "Configuracoes_TableViewController.h"
#import "Password_ViewController.h"
#import "SFHFKeychainUtils.h"
#import "Login_ViewController.h"
#import "WebViewController.h"

@implementation Configuracoes_TableViewController

#pragma mark - @synthesize

@synthesize configOptions;

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	[self setTitle:@"Configurações"];

	UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 35)];
	[backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
	backButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
	[backButton setTitleEdgeInsets:UIEdgeInsetsMake(0,3,0,0)];
	[backButton setTitle:@"Voltar" forState:UIControlStateNormal];
	[backButton setBackgroundImage:[UIImage imageNamed:@"button_back.png"] forState:UIControlStateNormal];
	[backButton setBackgroundImage:[UIImage imageNamed:@"button_back_selected.png"] forState:UIControlStateHighlighted];
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:backButton] autorelease]];
	[backButton release]; backButton = nil;

	[self.tableView setSeparatorColor:TABLESEPARATORCOLOR];
	[self.tableView setScrollEnabled:NO];
	[self.tableView setSectionHeaderHeight:33.0f];
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

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	BOOL isLogged = ([[NSUserDefaults standardUserDefaults] objectForKey:@"CREDENTIALS"] != nil);

	NSMutableArray *arraySync = [NSMutableArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
																 @"Conta para Sincronização", @"rowTitle",
																 [NSNumber numberWithInt:UITableViewCellAccessoryDisclosureIndicator], @"rowAccessoryType",
																 @"LabelOnly", @"rowStyle",
																 nil]];
	if (isLogged) {
		[arraySync addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							  @"Sincronizar", @"rowTitle",
							  [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
							  @"LabelOnly", @"rowStyle",
							  nil]];
	}
	NSDictionary *optionSync = [NSDictionary dictionaryWithObjectsAndKeys:
								@"Sincronização", @"sectionTitle",
								@"", @"sectionComments",
								arraySync, @"rowContent",
								nil];
	arraySync = nil;

	self.configOptions = [NSMutableArray arrayWithObject:optionSync];

	optionSync = nil;

    /* Removed block
	NSDictionary *optionBlock = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"Segurança", @"sectionTitle",
								 @"Ative o Bloqueio por Código e sempre que acessar o App, o mesmo pedirá uma senha para proteção", @"sectionComments",
								 [NSArray arrayWithObjects:
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   @"Bloqueio por Código", @"rowTitle",
								   [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
								   @"LabelAndSwitch", @"rowStyle",
								   nil],
								  nil], @"rowContent",
								 nil];
     
     */
	
	/*
	if (!isLogged) {
		NSDictionary *optionBuy = [NSDictionary dictionaryWithObjectsAndKeys:
								   @"Comprar", @"sectionTitle",
								   @"", @"sectionComments",
								   [NSArray arrayWithObjects:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 @"Comprar", @"rowTitle",
									 [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
									 @"LabelAndButton", @"rowStyle",
									 nil],
									nil], @"rowContent",
								   nil];
		[self.configOptions addObject:optionBuy];
		optionBuy = nil;
	}
	 */
    
    /* Removed block
	[self.configOptions addObject:optionBlock];

	optionBlock = nil;
    */

	NSDictionary *optionMais = [NSDictionary dictionaryWithObjectsAndKeys:
								@"", @"sectionTitle",
								@"", @"sectionComments",
								[NSArray arrayWithObjects:
								 [NSDictionary dictionaryWithObjectsAndKeys:
								  @"Organizze Mais", @"rowTitle",
								  [NSNumber numberWithInt:UITableViewCellAccessoryDisclosureIndicator], @"rowAccessoryType",
								  @"LabelOnly", @"rowStyle",
								  nil],
								 nil], @"rowContent",
								nil];
	arraySync = nil;
	
	[self.configOptions addObject:optionMais];

	optionMais = nil;

	[self.tableView reloadData];
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
	return [self.configOptions count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.sectionHeaderHeight)] autorelease];
	[headerView setBackgroundColor:[UIColor clearColor]];
	
	UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 0, headerView.frame.size.width - 40, headerView.frame.size.height)] autorelease];
	[headerLabel setBackgroundColor:[UIColor clearColor]];
	[headerLabel setTextColor:GRAYOVERWHITECOLOR];			
	[headerLabel setText:[[self.configOptions objectAtIndex:section] objectForKey:@"sectionTitle"]];
	
	[headerView addSubview:headerLabel];
	headerLabel = nil;
	
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	CGSize footerSize = [[sharedMethods shared] viewSizeForText:[[self.configOptions objectAtIndex:section] objectForKey:@"sectionComments"] usingFont:[UIFont systemFontOfSize:12]];
	return footerSize.height + 4;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	CGSize footerSize = [[sharedMethods shared] viewSizeForText:[[self.configOptions objectAtIndex:section] objectForKey:@"sectionComments"] usingFont:[UIFont systemFontOfSize:12]];
	UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, footerSize.height + 4)] autorelease];
	[footerView setBackgroundColor:[UIColor clearColor]];
	
	UILabel *footerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 0, footerView.frame.size.width - 40, footerView.frame.size.height)] autorelease];
	[footerLabel setBackgroundColor:[UIColor clearColor]];
	[footerLabel setTextColor:GRAYOVERWHITECOLOR];
	[footerLabel setFont:[UIFont systemFontOfSize:12]];
	[footerLabel setTextAlignment:UITextAlignmentCenter];
	[footerLabel setLineBreakMode:UILineBreakModeWordWrap];
	[footerLabel setNumberOfLines:0];
	[footerLabel setText:[[self.configOptions objectAtIndex:section] objectForKey:@"sectionComments"]];
	
	[footerView addSubview:footerLabel];
	footerLabel = nil;

	return footerView;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return [[[self.configOptions objectAtIndex:section] objectForKey:@"rowContent"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	} else {
		for (UIButton *buy in [cell.contentView subviews]) {
			if ([buy isKindOfClass:[UIButton class]]) {
				[buy removeFromSuperview];
			}
		}
		UISwitch *blockSwitch = (UISwitch *)[cell.contentView viewWithTag:999];
		[blockSwitch removeFromSuperview];
	}

	// Configure the cell...
	cell.accessoryType = [[[[[self.configOptions objectAtIndex:indexPath.section] objectForKey:@"rowContent"] objectAtIndex:indexPath.row] objectForKey:@"rowAccessoryType"] integerValue];
	cell.textLabel.text = [[[[self.configOptions objectAtIndex:indexPath.section] objectForKey:@"rowContent"] objectAtIndex:indexPath.row] objectForKey:@"rowTitle"];

	if ([[[[[self.configOptions objectAtIndex:indexPath.section] objectForKey:@"rowContent"] objectAtIndex:indexPath.row] objectForKey:@"rowStyle"] isEqualToString:@"LabelAndButton"]) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;

		UIButton *buy = [[[UIButton alloc] initWithFrame:CGRectMake(197, 6, 94, 32)] autorelease];
		[buy setTag:1000 + indexPath.row];
		[buy setAdjustsImageWhenHighlighted:YES];
		[buy setBackgroundImage:[UIImage imageNamed:@"botao.png"] forState:UIControlStateNormal];
		[buy setTitle:[NSString stringWithFormat:@"%@", @"price"] forState:UIControlStateNormal];
		[buy setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		buy.titleLabel.font = [UIFont boldSystemFontOfSize:17];
		[buy addTarget:self action:@selector(buyMoreCredit:) forControlEvents:UIControlEventTouchUpInside];
		[buy setHidden:NO];
		[cell.contentView addSubview:buy];
		buy = nil;

	} else if ([[[[[self.configOptions objectAtIndex:indexPath.section] objectForKey:@"rowContent"] objectAtIndex:indexPath.row] objectForKey:@"rowStyle"] isEqualToString:@"LabelAndSwitch"]) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;

		int extra = ([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)] ? 15 : 0);
		UISwitch *blockSwitch = [[[UISwitch alloc] initWithFrame: CGRectMake(197 + extra, 9, 94, 27)] autorelease];
		[blockSwitch addTarget:self action:@selector(blockApp:) forControlEvents:UIControlEventValueChanged];
		[blockSwitch setTag:999];
		NSString *password = [SFHFKeychainUtils getPasswordForUsername:@"organizze" andServiceName:@"omz:software Organizze" error:NULL];
		[blockSwitch setOn:([password length] == 4 ? 1 : 0) animated:NO];
		[cell.contentView addSubview:blockSwitch];
		blockSwitch = nil; password = nil;

	} else {
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Navigation logic may go here. Create and push another view controller.
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {	// Login
			Login_ViewController *detailViewController = [[Login_ViewController alloc] initWithStyle:UITableViewStyleGrouped];
			detailViewController.firstTime = NO;
			[self.navigationController pushViewController:detailViewController animated:YES];
			[detailViewController release];
		}

		if (indexPath.row == 1) {	// Syncronize
			whatToDo = WHATTODO_SYNC;
			[[parser shared] setDelegate:self];
			[[parser shared] setRequest:nil];
			[[parser shared] checkNetwork];
		}
	}

    //Removed block
	//if (indexPath.section == 2) {
    if (indexPath.section == 1) {
		whatToDo = WHATTODO_MAIS;
		[[parser shared] setDelegate:self];
		[[parser shared] setRequest:nil];
		[[parser shared] checkNetwork];
	}
}

#pragma mark - View Methods

- (void)back {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)blockApp:(id)sender {
	UISwitch *blockSwitch = (UISwitch *)sender;

	if ([blockSwitch isOn]) {
		// Ask for password
		Password_ViewController *anotherViewController = [[Password_ViewController alloc] initWithNibName:@"Password_ViewController" bundle:nil];
		anotherViewController.askForPassword = YES;
		[self.navigationController presentModalViewController:anotherViewController animated:YES];
		[anotherViewController release]; anotherViewController = nil;

	} else {
		// Reset password
		[SFHFKeychainUtils deleteItemForUsername:@"organizze" andServiceName:@"omz:software Organizze" error:NULL];

	}
}

#pragma mark - Notification methods

// Função acessada quando NSNotificationCenter recebe um evento
- (void)trackNotifications:(NSNotification *)notification {
	if ([[notification name] isEqualToString:@"NONETWORKNOTIFICATION"]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"NONETWORKNOTIFICATION" object:nil];
	}
}

#pragma mark - parser Delegate methods

- (void)showNoNetworkErrorMessage {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackNotifications:) name:@"NONETWORKNOTIFICATION" object:nil];
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkMessageWithCancelButton:YES];
}

- (void)processNetworkActivity {
	[[parser shared] setDelegate:nil];

	if (whatToDo == WHATTODO_SYNC) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SYNCHRONIZE" object:nil];
	} else if (whatToDo == WHATTODO_MAIS) {
		WebViewController *anotherViewController = [[[WebViewController alloc] initWithNibName:@"WebView" bundle:nil] autorelease];
		anotherViewController.newsURL = [NSURL URLWithString:ORGANIZZEMAIS];
		UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:anotherViewController] autorelease];
		[navigationController setDelegate:(AppDelegate *)[[UIApplication sharedApplication] delegate]];
		[anotherViewController.navigationItem setTitle:@"Organizze Mais"];
		[self presentModalViewController:navigationController animated:YES];
		navigationController = nil; anotherViewController = nil;
	}
}

@end
