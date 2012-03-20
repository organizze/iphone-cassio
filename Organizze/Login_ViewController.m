//
//  Login_ViewController.m
//  Organizze
//
//  Created by Cassio Rossi on 11/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "Login_ViewController.h"
#import "SFHFKeychainUtils.h"
#import "WebViewController.h"

@implementation Login_ViewController

#pragma mark - @synthesize

@synthesize firstTime, key, transfer, transfer_month;
@synthesize managedObjectContext = __managedObjectContext;

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	self.transfer = nil;
	self.transfer_month = nil;
	self.key = nil;
	[__managedObjectContext release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	if (!firstTime) {		
		[self setTitle:@"Conta"];

		UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 35)];
		[backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
		backButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
		[backButton setTitleEdgeInsets:UIEdgeInsetsMake(0,3,0,0)];
		[backButton setTitle:@"Voltar" forState:UIControlStateNormal];
		[backButton setBackgroundImage:[UIImage imageNamed:@"button_back.png"] forState:UIControlStateNormal];
		[backButton setBackgroundImage:[UIImage imageNamed:@"button_back_selected.png"] forState:UIControlStateHighlighted];
		[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:backButton] autorelease]];
		[backButton release]; backButton = nil;
	}

	[self.tableView setScrollEnabled:NO];
	[self.tableView setSectionFooterHeight:0];
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

	[self.navigationController setNavigationBarHidden:firstTime animated:NO];

	[[parser shared] setDelegate:self];
	[[parser shared] checkNetwork];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	if (firstTime) {
		[self.navigationController setNavigationBarHidden:NO animated:NO];
	}
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
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"CREDENTIALS"] != nil ? 2 : 4);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	CGFloat returnValue = 0;

	switch (section) {
		case 0:
			returnValue = 88 + (firstTime ? 44 : 0);
			break;
		case 1:
			returnValue = 0;
			break;
		case 2:
			returnValue = 0;
			break;
		case 3:
			returnValue = 120;
			break;
		default:
			break;
	}
	return returnValue;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 88 + (firstTime ? 44 : 0))] autorelease];
	[headerView setBackgroundColor:[UIColor clearColor]];
	
	if (section == 0) {
		if (firstTime) {
			UIImageView *logo = [[[UIImageView alloc] initWithFrame:CGRectMake(10, 54, headerView.frame.size.width - 20, headerView.frame.size.height)] autorelease];
			[logo setContentMode:UIViewContentModeTopLeft];
			[logo setImage:[UIImage imageNamed:@"logo.png"]];
			[headerView addSubview:logo];
			logo = nil;
		} else {
			UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 10, headerView.frame.size.width - 40, 30)] autorelease];
			[headerLabel setBackgroundColor:[UIColor clearColor]];
			[headerLabel setTextColor:GRAYOVERWHITECOLOR];			
			[headerLabel setText:@"Sincronização"];
			[headerView addSubview:headerLabel];

			headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 35, headerView.frame.size.width - 40, 44)] autorelease];
			[headerLabel setBackgroundColor:[UIColor clearColor]];
			[headerLabel setNumberOfLines:2];
			[headerLabel setLineBreakMode:UILineBreakModeWordWrap];
			[headerLabel setTextColor:GRAYOVERWHITECOLOR];
			[headerLabel setText:@"Altere aqui os dados de sua conta para sincronização"];
			[headerLabel setFont:[UIFont systemFontOfSize:14]];
			[headerView addSubview:headerLabel];

			headerLabel = nil;
		}
	}
	
	return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return (section == 0 ? 2 : 1);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath.section > 1 ? 22 : 44);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
	[self.tableView setSeparatorColor:[UIColor clearColor]];

	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
		[cell.textLabel setTextAlignment:UITextAlignmentCenter];
		if ([cell respondsToSelector:@selector(setBackgroundView:)]) {
			[cell setBackgroundView:nil];
			[cell setBackgroundColor:[UIColor clearColor]];
		} else {
			[cell setBackgroundColor:[UIColor clearColor]];
		}
	} else {
		UILabel *txt1 = (UILabel *)[cell.contentView viewWithTag:2000];
		[txt1 removeFromSuperview]; txt1 = nil;
		UILabel *txt2 = (UILabel *)[cell.contentView viewWithTag:2001];
		[txt2 removeFromSuperview]; txt2 = nil;
	}

	// Configure the cell...

	switch (indexPath.section) {
		case 0: {	// Login
			[self.tableView setSeparatorColor:TABLESEPARATORCOLOR];
			[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];

			TextAndInput_Cell *loginCell = (TextAndInput_Cell *)[self.tableView dequeueReusableCellWithIdentifier:@"cell"];
			if (loginCell == nil) {
				loginCell = [[[NSBundle mainBundle] loadNibNamed:@"TextAndInput_Cell" owner:nil options:nil] objectAtIndex:0];
				[loginCell setSelectionStyle:UITableViewCellSelectionStyleNone];
				[loginCell setAccessoryType:UITableViewCellAccessoryNone];
				[loginCell.input setDelegate:self];
				[loginCell.input setAutocorrectionType:UITextAutocorrectionTypeNo];
			}

			[loginCell.input setTag:(1000 + indexPath.row)];

			if (indexPath.row == 0) {
				[loginCell.separatorLine setHidden:NO];
				[loginCell.label setText:@"Usuário"];
				[loginCell.input setPlaceholder:@"Digite seu e-mail"];
				[loginCell.input setKeyboardType:UIKeyboardTypeEmailAddress];
				[loginCell.input setSecureTextEntry:NO];
				[loginCell.input setEnabled:YES];
				if ([[NSUserDefaults standardUserDefaults] objectForKey:@"CREDENTIALS"] != nil) {
					[loginCell.input setText:[[[NSUserDefaults standardUserDefaults] objectForKey:@"CREDENTIALS"] objectForKey:@"USUARIO"]];
					[loginCell.input setEnabled:NO];
				}
			} else {
				[loginCell.separatorLine setHidden:YES];
				[loginCell.label setText:@"Senha"];
				[loginCell.input setPlaceholder:@"Digite sua senha"];
				[loginCell.input setKeyboardType:UIKeyboardTypeDefault];
				[loginCell.input setSecureTextEntry:YES];
				[loginCell.input setEnabled:YES];
				if ([[NSUserDefaults standardUserDefaults] objectForKey:@"CREDENTIALS"] != nil) {
					[loginCell.input setText:[[[NSUserDefaults standardUserDefaults] objectForKey:@"CREDENTIALS"] objectForKey:@"SENHA"]];
					[loginCell.input setEnabled:NO];
				}
			}
			return loginCell;
		} break;

		case 1: {	// Acessar
			if ([[NSUserDefaults standardUserDefaults] objectForKey:@"CREDENTIALS"] != nil) {
				[cell.textLabel setText:@"Sair"];
			} else {
				[cell.textLabel setText:@"Acessar"];
			}
			[cell.textLabel setTextColor:[UIColor whiteColor]];
			if ([cell respondsToSelector:@selector(setBackgroundView:)]) {
				[cell setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"botao.png"]] autorelease]];
				[cell setBackgroundColor:[UIColor clearColor]];
			} else {
				[cell setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"botao.png"]]];
			}
		} break;

		case 2: {	// Senha
			[cell.textLabel setText:@"Esqueci a senha"];
			[cell.textLabel setFont:[UIFont boldSystemFontOfSize:12]];
			[cell.textLabel setTextColor:GREENTEXTCOLOR];
		} break;

		case 3: {	// Cadastro
			UILabel *textLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 0, 152, 22)] autorelease];
			[textLabel setBackgroundColor:[UIColor clearColor]];
			[textLabel setText:@"Ainda não é usuário?"];
			[textLabel setTextColor:[UIColor blackColor]];
			[textLabel setFont:[UIFont boldSystemFontOfSize:12]];
			[textLabel setTextAlignment:UITextAlignmentRight];
			[textLabel setTag:2000];
			[cell.contentView addSubview:textLabel];
			textLabel = nil;

			UILabel *detailTextLabel = [[[UILabel alloc] initWithFrame:CGRectMake(180, 0, 120, 22)] autorelease];
			[detailTextLabel setBackgroundColor:[UIColor clearColor]];
			[detailTextLabel setText:@"Cadastre-se"];
			[detailTextLabel setTextColor:GREENTEXTCOLOR];			
			[detailTextLabel setFont:[UIFont boldSystemFontOfSize:12]];
			[detailTextLabel setTextAlignment:UITextAlignmentLeft];
			[detailTextLabel setTag:2001];
			[cell.contentView addSubview:detailTextLabel];
			detailTextLabel= nil;

			return cell;
		} break;
			
		default:
			break;
	}

	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if (indexPath.section == 1) {
		if ([[NSUserDefaults standardUserDefaults] objectForKey:@"CREDENTIALS"] != nil) {
			TextAndInput_Cell *cell0 = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
			[cell0.input setText:@""];
			UITextField *usuarioField = (UITextField *)[cell0.contentView viewWithTag:1000];
			[usuarioField resignFirstResponder];			
			usuarioField = nil; cell0 = nil;

			TextAndInput_Cell *cell1 = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
			[cell1.input setText:@""];
			UITextField *senhaField = (UITextField *)[cell1.contentView viewWithTag:1001];
			[senhaField resignFirstResponder];
			senhaField = nil; cell1 = nil;

			NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];			
			NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];

			NSEntityDescription *userConfig = [NSEntityDescription entityForName:@"User_Config" inManagedObjectContext:context];
			[fetchRequest setEntity:userConfig];
			NSArray *userArray = [context executeFetchRequest:fetchRequest error:nil];
			for (NSManagedObject *object in userArray) {
				[context deleteObject:object];
			}
			userArray = nil; userConfig = nil;

			NSEntityDescription *tags = [NSEntityDescription entityForName:@"Tags" inManagedObjectContext:context];
			[fetchRequest setEntity:tags];
			NSArray *tagsArray = [context executeFetchRequest:fetchRequest error:nil];
			for (NSManagedObject *object in tagsArray) {
				[context deleteObject:object];
			}
			tagsArray = nil; tags = nil;

			NSEntityDescription *userAccounts = [NSEntityDescription entityForName:@"Accounts" inManagedObjectContext:context];
			[fetchRequest setEntity:userAccounts];
			NSArray *accountsArray = [context executeFetchRequest:fetchRequest error:nil];
			for (NSManagedObject *object in accountsArray) {
				[context deleteObject:object];
			}
			accountsArray = nil; userAccounts = nil;

			NSEntityDescription *transactions = [NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:context];
			[fetchRequest setEntity:transactions];
			NSArray *transactionsArray = [context executeFetchRequest:fetchRequest error:nil];
			for (NSManagedObject *object in transactionsArray) {
				[context deleteObject:object];
			}
			transactionsArray = nil; transactions = nil;

			fetchRequest = nil;

			NSError *error = nil;
			if (![context save:&error]) {
				// Replace this implementation with code to handle the error appropriately.
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			}
			context = nil;

			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CREDENTIALS"];
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LASTSYNC"];
			[[NSUserDefaults standardUserDefaults] synchronize];

			[SFHFKeychainUtils deleteItemForUsername:@"organizze" andServiceName:@"omz:software Organizze" error:NULL];

			[self.tableView reloadData];
			[self.navigationItem setLeftBarButtonItem:nil];
			[self.navigationItem setHidesBackButton:YES];

		} else {
			[self doLogin];
		}
	}

	if (indexPath.section == 2) {
		TextAndInput_Cell *cell0 = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		UITextField *usuarioField = (UITextField *)[cell0.contentView viewWithTag:1000];
		[usuarioField resignFirstResponder];
		
		TextAndInput_Cell *cell1 = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
		UITextField *senhaField = (UITextField *)[cell1.contentView viewWithTag:1001];
		[senhaField resignFirstResponder];
		
		[self reposicionarView];
		
		if ([usuarioField.text length] > 0) {
			[[parser shared] setDelegate:self];
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
								  USERPASSWORD, @"url",
								  [NSString stringWithFormat:@"<user><email>%@</email></user><device-id>%@</device-id>", usuarioField.text, [[sharedMethods shared] getMyUDID]], @"body",
								  nil];
			[[parser shared] parse:GETUSERPASSWORD withParam:dict];
			dict = nil;

			[self showSyncMessage:YES];
		} else {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Organizze"
															 message:@"Preencha o campo Usuário"
															delegate:nil
												   cancelButtonTitle:@"Fechar"
												   otherButtonTitles:nil] autorelease];
			[alert show]; alert = nil;
		}
		
		senhaField = nil; cell1 = nil;
		usuarioField = nil; cell0 = nil;
	}

	if (indexPath.section == 3) {
		WebViewController *anotherViewController = [[[WebViewController alloc] initWithNibName:@"WebView" bundle:nil] autorelease];
		anotherViewController.newsURL = [NSURL URLWithString:USERREGISTRY];
		UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:anotherViewController] autorelease];
		[navigationController setDelegate:(AppDelegate *)[[UIApplication sharedApplication] delegate]];
		[anotherViewController.navigationItem setTitle:@"Cadastre-se"];
		[self presentModalViewController:navigationController animated:YES];
		navigationController = nil; anotherViewController = nil;
	}
}

#pragma mark - Keyboard methods

// Tratar aparencia do teclado e visibilidade
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	[UIView animateWithDuration:0.2f
					 animations:^{
						 [self.view setFrame:CGRectMake(0, (firstTime ? -40 : -80), self.view.frame.size.width, self.view.frame.size.height)];
					 }
	 ];

	return YES;
}

// Tratar comportamento da tecla ENTER
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self reposicionarView];
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - Notification methods

// Função acessada quando NSNotificationCenter recebe um evento
- (void)trackNotifications:(NSNotification *)notification {
	if ([[notification name] isEqualToString:@"NONETWORKNOTIFICATION"]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"NONETWORKNOTIFICATION" object:nil];
		[self back];
	}
}

#pragma mark - parser Delegate methods

- (void)showNoNetworkErrorMessage {
	[self showSyncMessage:NO];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackNotifications:) name:@"NONETWORKNOTIFICATION" object:nil];
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkMessageWithCancelButton:!firstTime];
}

- (void)showNetworkErrorMessage {
	[self showSyncMessage:NO];
}

- (void)showErrorMessage {
	[self showSyncMessage:NO];
}

- (void)returnFromParse:(id)parsedObject withData:(NSData *)parsedData {
	BOOL destroyParse = NO;

	id response = [NSKeyedUnarchiver unarchiveObjectWithData:parsedData];
	if ([response isKindOfClass:[NSArray class]]) {
		switch ([(parser *)parsedObject whatToDo]) {
			case DOUSERLOGIN: {
				NSMutableArray *responseArray = [NSMutableArray arrayWithArray:(NSArray *)response];
				if ([responseArray count] > 0) {
					self.key = [[responseArray objectAtIndex:0] objectForKey:@"api_key"];
					[[parser shared] parse:OBTERUSERSETTINGS withParam:[NSDictionary dictionaryWithObjectsAndKeys:USERSETTINGS, @"url", self.key, @"key", nil]];

				} else {
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CREDENTIALS"];
					[self showSyncMessage:NO];
					destroyParse = YES;
				}
				responseArray = nil;
			} break;

			case OBTERUSERSETTINGS: {
				NSMutableArray *responseArray = [NSMutableArray arrayWithArray:(NSArray *)response];
				if ([responseArray count] > 0) {
					// Save data to CORE DATA
					NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];

					for (NSDictionary *dict in responseArray) {
						NSManagedObject *userConfig = [NSEntityDescription insertNewObjectForEntityForName:@"User_Config" inManagedObjectContext:context];
						[userConfig setValue:[NSNumber numberWithBool:[[dict objectForKey:@"transactions_consider_only_done_outcomes"] boolValue]] forKey:@"transactions_consider_only_done_outcomes"];
						[userConfig setValue:[NSNumber numberWithBool:[[dict objectForKey:@"transactions_consider_only_done_incomes"] boolValue]] forKey:@"transactions_consider_only_done_incomes"];
						[userConfig setValue:[NSNumber numberWithBool:[[dict objectForKey:@"transactions_transfer_result"] boolValue]] forKey:@"transactions_transfer_result"];
						[userConfig setValue:[NSNumber numberWithBool:[[dict objectForKey:@"transactions_set_done"] boolValue]] forKey:@"transactions_set_done"];
						[userConfig setValue:[dict objectForKey:@"transactions_transfer_result_start_month"] forKey:@"transactions_transfer_result_start_month"];
						[userConfig setValue:[dict objectForKey:@"versao_mais"] forKey:@"versao_mais"];
						userConfig = nil;

						self.transfer_month = [dict objectForKey:@"transactions_transfer_result_start_month"];
						self.transfer = [dict objectForKey:@"transactions_transfer_result"];
					}

					// Save the context.
					NSError *error = nil;
					if (![context save:&error]) {
						// Replace this implementation with code to handle the error appropriately.
						NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
					}

					context = nil;

					[[parser shared] parse:OBTERUSERCATEGORIES withParam:[NSDictionary dictionaryWithObjectsAndKeys:USERCATEGORY, @"url", self.key, @"key", nil]];

				} else {
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CREDENTIALS"];
					[self showSyncMessage:NO];
					destroyParse = YES;
				}
				responseArray = nil;
			} break;

			case OBTERUSERCATEGORIES: {
				NSMutableArray *responseArray = [NSMutableArray arrayWithArray:(NSArray *)response];
				if ([responseArray count] > 0) {
					// Save data to CORE DATA
					NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];					
					for (NSDictionary *dict in responseArray) {
						NSManagedObject *tags = [NSEntityDescription insertNewObjectForEntityForName:@"Tags" inManagedObjectContext:context];
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
						
						[tags setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"id"] integerValue]] forKey:@"id"];
						[tags setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"parent_id"] integerValue]] forKey:@"parent_id"];
						
						[tags setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"created_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"created_at"];
						[tags setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"updated_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"updated_at"];
						[tags setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"deleted_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"deleted_at"];
						tags = nil;
					}

					// Save the context.
					NSError *error = nil;
					if (![context save:&error]) {
						// Replace this implementation with code to handle the error appropriately.
						NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
					}
					
					context = nil;
					
					[[parser shared] parse:OBTERUSERACCOUNTS withParam:[NSDictionary dictionaryWithObjectsAndKeys:USERACCOUNTS, @"url",self.key, @"key", nil]];

				} else {
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CREDENTIALS"];
					[self showSyncMessage:NO];
					destroyParse = YES;
				}
				
				responseArray = nil;
			} break;

			case OBTERUSERACCOUNTS: {
				NSMutableArray *responseArray = [NSMutableArray arrayWithArray:(NSArray *)response];
				if ([responseArray count] > 0) {
					// Save data to CORE DATA
					NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];					
					for (NSDictionary *dict in responseArray) {
						NSManagedObject *userAccounts = [NSEntityDescription insertNewObjectForEntityForName:@"Accounts" inManagedObjectContext:context];
						[userAccounts setValue:[NSNumber numberWithBool:[[dict objectForKey:@"none"] boolValue]] forKey:@"none"];
						[userAccounts setValue:[dict objectForKey:@"flag"] forKey:@"flag"];
						[userAccounts setValue:[dict objectForKey:@"flag_icon"] forKey:@"flag_icon"];
						[userAccounts setValue:[dict objectForKey:@"icon"] forKey:@"icon"];
						[userAccounts setValue:[dict objectForKey:@"kind"] forKey:@"kind"];
						[userAccounts setValue:[dict objectForKey:@"user_id"] forKey:@"user_id"];
						[userAccounts setValue:[dict objectForKey:@"name"] forKey:@"name"];
						[userAccounts setValue:[NSNumber numberWithInteger:[[dict objectForKey:@"id"] integerValue]] forKey:@"id"];						
						[userAccounts setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"created_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"created_at"];
						[userAccounts setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"updated_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"updated_at"];
						[userAccounts setValue:[[sharedMethods shared] dateFromFormattedString:[dict objectForKey:@"deleted_at"] usingFormat:@"yyyy-MM-dd'T'HH:mm:ss-SS:SS"] forKey:@"deleted_at"];
						userAccounts = nil;
					}
					
					// Save the context.
					NSError *error = nil;
					if (![context save:&error]) {
						// Replace this implementation with code to handle the error appropriately.
						NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
					}
					
					context = nil;

					TextAndInput_Cell *cell0 = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
					UITextField *usuarioField = (UITextField *)[cell0.contentView viewWithTag:1000];
					
					TextAndInput_Cell *cell1 = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
					UITextField *senhaField = (UITextField *)[cell1.contentView viewWithTag:1001];
					
					[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:
																	  usuarioField.text, @"USUARIO", 
																	  senhaField.text, @"SENHA", 
																	  self.key, @"KEY", 
																	  self.transfer, @"TRANSFER",
																	  self.transfer_month, @"TRANSFER_MONTH", 
																	  nil]
															  forKey:@"CREDENTIALS"];

					senhaField = nil; cell1 = nil;
					usuarioField = nil; cell0 = nil;

					// Finish LOGIN processing
					[self showSyncMessage:NO];
					[[NSNotificationCenter defaultCenter] postNotificationName:@"GETNEWDATA" object:nil];
					
					if (firstTime) {
						[self dismissModalViewControllerAnimated:YES];
					} else {
						[self.navigationController popToRootViewControllerAnimated:YES];
					}
					
				} else {
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CREDENTIALS"];
					[self showSyncMessage:NO];
					destroyParse = YES;
				}
				
				responseArray = nil;
				
			} break;

			default:
				break;
		}
	} else if ([response isKindOfClass:[NSString class]]) {
		if ([(parser *)parsedObject whatToDo] == DOUSERLOGIN ||
			[(parser *)parsedObject whatToDo] == GETUSERPASSWORD) {

			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Organizze"
															 message:(NSString *)response
															delegate:nil
												   cancelButtonTitle:@"Fechar"
												   otherButtonTitles:nil] autorelease];
			[alert show]; alert = nil;

			if ([(parser *)parsedObject whatToDo] == DOUSERLOGIN) {
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CREDENTIALS"];
			}

			[self showSyncMessage:NO];
			
			destroyParse = YES;
		}
	}
	response = nil;

	if (destroyParse) {
		[[parser shared] setDelegate:nil];
		[[parser shared] destroy];
	}
}

#pragma mark - View Methods

- (void)showSyncMessage:(BOOL)show {
	if (show) {
		NSDictionary *syncMessage = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Acessando", @"title", 
									 @"Autenticando o usuário", @"message", 
									 [NSNumber numberWithBool:YES], @"showArrow", 
									 [NSNumber numberWithBool:NO], @"showCancel", nil];
		[(AppDelegate *)[[UIApplication sharedApplication] delegate] showSyncMessage:YES withMessages:syncMessage];
		syncMessage = nil;
		
	} else {
		[(AppDelegate *)[[UIApplication sharedApplication] delegate] showSyncMessage:NO withMessages:nil];
	}
}

- (void)back {
	if (firstTime) {
		[self dismissModalViewControllerAnimated:YES];
	} else {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)reposicionarView {
	[UIView animateWithDuration:0.2f
					 animations:^{
						 [self.view setFrame:CGRectMake(0, (firstTime ? 20 : 0), self.view.frame.size.width, self.view.frame.size.height)];
					 }
	 ];
}

- (void)doLogin {
	TextAndInput_Cell *cell0 = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	UITextField *usuarioField = (UITextField *)[cell0.contentView viewWithTag:1000];
	[usuarioField resignFirstResponder];

	TextAndInput_Cell *cell1 = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
	UITextField *senhaField = (UITextField *)[cell1.contentView viewWithTag:1001];
	[senhaField resignFirstResponder];

	[self reposicionarView];

	if ([usuarioField.text length] > 0 && [senhaField.text length] > 0) {
		[[parser shared] setDelegate:self];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  USERLOGIN, @"url",
							  [NSString stringWithFormat:@"<user><email>%@</email><password>%@</password></user>", usuarioField.text, senhaField.text], @"body",
							  nil];
		[[parser shared] parse:DOUSERLOGIN withParam:dict];
		dict = nil;

		[self showSyncMessage:YES];
	}

	senhaField = nil; cell1 = nil;
	usuarioField = nil; cell0 = nil;
}

@end
