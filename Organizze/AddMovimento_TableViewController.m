//
//  AddMovimento_TableViewController.m
//  Organizze
//
//  Created by Cassio Rossi on 30/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "AddMovimento_TableViewController.h"
#import "MoreData_TableViewController.h"
#import "DatePicker_ViewController.h"
#import "Timeframe_ViewController.h"

@implementation AddMovimento_TableViewController

#pragma mark - @synthesize

@synthesize context, transaction, tableConfig;
@synthesize previousSelectedRow;
@synthesize currentMonth, originalDate;

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PARCELAMENTO"];

	keyboardIsVisible = NO;
	// add observer for the respective notifications (depending on the os version)
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];		
	} else {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	}

	NSArray *deleteArray = nil;

	self.context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
	// Obter configuracoes padrao
	BOOL transactions_set_done = NO;
	versaoMais = NO;

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"User_Config" inManagedObjectContext:self.context]];
	for (NSManagedObject *object in [self.context executeFetchRequest:fetchRequest error:nil]) {
		transactions_set_done = [[object valueForKey:@"transactions_set_done"] boolValue];
		versaoMais = [[object valueForKey:@"versao_mais"] boolValue];
	}

    /*
     int account_id = 0;
     [fetchRequest setEntity:[NSEntityDescription entityForName:@"Accounts" inManagedObjectContext:self.context]];
     
     for (NSManagedObject *object in [self.context executeFetchRequest:fetchRequest error:nil]) {
         if ([[object valueForKey:@"none"] boolValue]) {
            account_id = [[object valueForKey:@"id"] integerValue];
        }
     }
     */ 
    //Show only accounts not deleted and sort by name
	int account_id = 0;
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Accounts" inManagedObjectContext:self.context]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]]];
    NSSortDescriptor *sortByName = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortByName]];
    
	for (NSManagedObject *object in [self.context executeFetchRequest:fetchRequest error:nil]) {
        account_id = [[object valueForKey:@"id"] integerValue];
        break;
	}
     

	int tag_id = 0;
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Tags" inManagedObjectContext:self.context]];	
	for (NSManagedObject *object in [self.context executeFetchRequest:fetchRequest error:nil]) {
		if ([[object valueForKey:@"none"] boolValue]) {
			tag_id = [[object valueForKey:@"id"] integerValue];
		}
	}

	[fetchRequest release]; fetchRequest = nil;

	// Inicializar o objeto TRANSACTION
	if (self.transaction == nil) {
		self.title = @"Adicionando";
		isNewTransaction = YES;

		self.transaction = [NSEntityDescription insertNewObjectForEntityForName:@"Transactions" inManagedObjectContext:self.context];

		[self.transaction setValue:[NSNumber numberWithInteger:tag_id] forKey:@"tag_id"];
		[self.transaction setValue:[NSNumber numberWithInteger:account_id] forKey:@"account_id"];

		// Get existing data
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Accounts" inManagedObjectContext:self.context]];

		NSManagedObject *accountObject = [[self.context executeFetchRequest:fetchRequest error:nil] objectAtIndex:0];
		[self.transaction setValue:[accountObject valueForKey:@"user_id"] forKey:@"user_id"];
		accountObject = nil;

		[self.transaction setValue:[NSDate date] forKey:@"created_at"];

		NSDate *selectedDate = [[sharedMethods shared] dateFromFormattedString:self.currentMonth usingFormat:@"yyyy-MM"];
		NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:selectedDate];
		NSDateComponents *allComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit) fromDate:[NSDate date]];
		[allComponents setYear:[components year]];
		[allComponents setMonth:[components month]];
		NSDate *newDate = [[NSCalendar currentCalendar] dateFromComponents:allComponents];
		allComponents = nil; components = nil; selectedDate = nil;

		[self.transaction setValue:[[sharedMethods shared] formattedStringFromDate:newDate usingFormat:@"yyyy-MM-dd"] forKey:@"date"];
		[self.transaction setValue:[NSNumber numberWithBool:([newDate compare:[NSDate date]] == NSOrderedAscending)] forKey:@"done"];
		[self.transaction setValue:[NSNumber numberWithBool:NO] forKey:@"income"];
		newDate = nil;

		NSDecimalNumber *amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:@"0"];
		[self.transaction setValue:amount forKey:@"ammount"];
		amount = nil;

		[self.transaction setValue:@"" forKey:@"description_text"];

		[self.transaction setValue:[NSNumber numberWithBool:NO] forKey:@"start_result"];
		[self.transaction setValue:[NSNumber numberWithBool:NO] forKey:@"transfer"];

		[self.transaction setValue:[NSNumber numberWithBool:NO] forKey:@"synced"];

		[self.transaction setValue:@"0" forKey:@"repeat_total"];
		[self.transaction setValue:@"0" forKey:@"repeat_index"];
		[self.transaction setValue:@"bills" forKey:@"repeat_type"];
		[self.transaction setValue:[NSNumber numberWithInt:0] forKey:@"repeat_finder"];
		[self.transaction setValue:@"" forKey:@"recurrence_uuid"];

		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.context]];
		
        //removed mobile_record_id
        //[self.transaction setValue:[NSNumber numberWithInt:[[self.context executeFetchRequest:fetchRequest error:nil] count]] forKey:@"mobile_record_id"];
		[fetchRequest release]; fetchRequest = nil;

		[self.transaction setValue:[[sharedMethods shared] generateUUID] forKey:@"uuid"];

	} else {
		self.title = @"Detalhes";
		isNewTransaction = NO;

		deleteArray = [NSArray arrayWithObjects:
					   [NSDictionary dictionaryWithObjectsAndKeys:
						@"Apagar", @"rowTitle",
						@"Text_Centered", @"rowType",
						[UIImage imageNamed:@"botao_vermelho.png"], @"rowBackgroundColor",
						[UIColor whiteColor], @"rowTextColor",
						nil], nil];
	}

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

	[self.tableView setScrollsToTop:YES];
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

	NSArray *tipo = [NSArray arrayWithObjects:
					 [NSDictionary dictionaryWithObjectsAndKeys:
					  @"Tipo", @"rowTitle",
					  @"", @"rowPlaceholder",
					  [NSNumber numberWithInt:UITableViewCellAccessoryDisclosureIndicator], @"rowAccessoryType",
					  [NSNumber numberWithInt:UITableViewCellSelectionStyleGray], @"rowSelectionType",
					  @"Text_Input", @"rowType",
					  [NSNumber numberWithBool:NO], @"rowShowKeyboard",
					  @"income", @"columnName",
					  @"", @"entityName",
					  @"", @"predicateColumn",
					  nil], nil];

	NSMutableArray *transacao = [NSMutableArray arrayWithObjects:
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   @"Descrição", @"rowTitle",
								   @"", @"rowPlaceholder",
								   [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
								   [NSNumber numberWithInt:UITableViewCellSelectionStyleNone], @"rowSelectionType",
								   @"Text_Input", @"rowType",
								   [NSNumber numberWithBool:YES], @"rowShowKeyboard",
								   [NSNumber numberWithInt:UIKeyboardTypeDefault], @"rowKeyboardType",
								   @"description_text", @"columnName",
								   @"", @"entityName",
								   @"", @"predicateColumn",
								   @"", @"format",
								   nil],
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   @"Valor", @"rowTitle",
								   @"", @"rowPlaceholder",
								   [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
								   [NSNumber numberWithInt:UITableViewCellSelectionStyleNone], @"rowSelectionType",
								   @"Text_Input", @"rowType",
								   [NSNumber numberWithBool:YES], @"rowShowKeyboard",
								   [NSNumber numberWithInt:UIKeyboardTypeNumberPad], @"rowKeyboardType",
								   @"ammount", @"columnName",
								   @"", @"entityName",
								   @"", @"predicateColumn",
								   @"currency", @"format",
								   nil],
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   @"Data", @"rowTitle",
								   @"", @"rowPlaceholder",
								   [NSNumber numberWithInt:UITableViewCellAccessoryDisclosureIndicator], @"rowAccessoryType",
								   [NSNumber numberWithInt:UITableViewCellSelectionStyleGray], @"rowSelectionType",
								   @"Text_Input", @"rowType",
								   [NSNumber numberWithBool:NO], @"rowShowKeyboard",
								   @"date", @"columnName",
								   @"", @"entityName",
								   @"", @"predicateColumn",
								   @"date", @"format",
								   nil],
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   @"Categoria", @"rowTitle",
								   @"", @"rowPlaceholder",
								   [NSNumber numberWithInt:UITableViewCellAccessoryDisclosureIndicator], @"rowAccessoryType",
								   [NSNumber numberWithInt:UITableViewCellSelectionStyleGray], @"rowSelectionType",
								   @"Text_Input", @"rowType",
								   [NSNumber numberWithBool:NO], @"rowShowKeyboard",
								   @"name", @"columnName",
								   @"Tags", @"entityName",
								   @"tag_id", @"predicateColumn",
								   @"", @"format",
								   nil],
								 nil];

	if (versaoMais) {
		[transacao addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Conta", @"rowTitle",
							   @"", @"rowPlaceholder",
							   [NSNumber numberWithInt:(versaoMais ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone)], @"rowAccessoryType",
							   [NSNumber numberWithInt:(versaoMais ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone)], @"rowSelectionType",
							   @"Text_Input", @"rowType",
							   [NSNumber numberWithBool:NO], @"rowShowKeyboard",
							   @"name", @"columnName",
							   @"Accounts", @"entityName",
							   @"account_id", @"predicateColumn",
							   @"", @"format",
							   nil]
		 ];
	}

	NSArray *recorrencia = [NSArray arrayWithObjects:
							[NSDictionary dictionaryWithObjectsAndKeys:
							 @"Repetir", @"rowTitle",
							 [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
							 [NSNumber numberWithInt:UITableViewCellSelectionStyleNone], @"rowSelectionType",
							 @"Text_Switch", @"rowType",
							 @"recurrence_uuid", @"columnName",
							 [NSNumber numberWithInt:1000], @"rowID", 
							 nil], 
							[NSDictionary dictionaryWithObjectsAndKeys:
							 [NSString stringWithFormat:@"É uma %@ fixa", ([[self.transaction valueForKey:@"income"] boolValue] ? @"receita" : @"despesa")], @"rowTitle",
							 @"Text_Left", @"rowType",
							 @"repeat_type", @"columnName",
							 [NSNumber numberWithInt:0], @"rowIndex",
							 [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
							 [NSNumber numberWithInt:UITableViewCellSelectionStyleGray], @"rowSelectionType",
							 @"bills", @"value",
							 nil],
							[NSDictionary dictionaryWithObjectsAndKeys:
							 [NSString stringWithFormat:@"É uma %@ parcelada", ([[self.transaction valueForKey:@"income"] boolValue] ? @"receita" : @"despesa")], @"rowTitle",
							 @"Text_Left", @"rowType",
							 @"repeat_type", @"columnName",
							 [NSNumber numberWithInt:1], @"rowIndex",
							 [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
							 [NSNumber numberWithInt:UITableViewCellSelectionStyleGray], @"rowSelectionType",
							 @"parc", @"value",
							 nil],
							nil];

	NSArray *recorrenciaEdit = [NSArray arrayWithObjects:
								[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSString stringWithFormat:@"%@ recorrente", ([[self.transaction valueForKey:@"income"] boolValue] ? @"Receita" : @"Despesa")], @"rowTitle",
								 [NSNumber numberWithInt:UITableViewCellAccessoryCheckmark], @"rowAccessoryType",
								 [NSNumber numberWithInt:UITableViewCellSelectionStyleNone], @"rowSelectionType",
								 @"Text_Left", @"rowType",
								 nil], 
								nil];

	NSArray *pago = [NSArray arrayWithObjects:
					 [NSDictionary dictionaryWithObjectsAndKeys:
					  @"Paga", @"rowTitle",
					  @"", @"rowPlaceholder",
					  [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
					  [NSNumber numberWithInt:UITableViewCellSelectionStyleNone], @"rowSelectionType",
					  @"Text_Switch", @"rowType",
					  [NSNumber numberWithInt:999], @"rowID", 
					  @"done", @"columnName",
					  nil], nil];

	self.tableConfig = [NSMutableArray arrayWithObjects:tipo, transacao, nil];

	if (isNewTransaction) {
		[self.tableConfig addObject:recorrencia];
	}

	if (transactions_set_done) {
		[self.tableConfig addObject:pago];
	}

	if (!isNewTransaction && ![[[self.transaction valueForKey:@"recurrence_uuid"] description] isEqualToString:@""]) {
		[self.tableConfig addObject:recorrenciaEdit];
	}

	if (!isNewTransaction) {
		[self.tableConfig addObject:deleteArray];
	}

	pago = nil; transacao = nil; tipo = nil; deleteArray = nil;
	recorrencia = nil;

	self.originalDate = [[sharedMethods shared] dateFromFormattedString:[[self.transaction valueForKey:@"date"] description] usingFormat:@"yyyy-MM-dd"];
	hasCanceled = NO;
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

	if (isNewTransaction && ![[[self.transaction valueForKey:@"recurrence_uuid"] description] isEqualToString:@""]) {
		NSArray *recorrencia = [NSArray arrayWithObjects:
								[NSDictionary dictionaryWithObjectsAndKeys:
								 @"Repetir", @"rowTitle",
								 [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
								 [NSNumber numberWithInt:UITableViewCellSelectionStyleNone], @"rowSelectionType",
								 @"Text_Switch", @"rowType",
								 @"recurrence_uuid", @"columnName",
								 [NSNumber numberWithInt:1000], @"rowID", 
								 nil], 
								[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSString stringWithFormat:@"É uma %@ fixa", ([[self.transaction valueForKey:@"income"] boolValue] ? @"receita" : @"despesa")], @"rowTitle",
								 @"Text_Left", @"rowType",
								 @"repeat_type", @"columnName",
								 [NSNumber numberWithInt:0], @"rowIndex",
								 [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
								 [NSNumber numberWithInt:UITableViewCellSelectionStyleGray], @"rowSelectionType",
								 @"bills", @"value",
								 nil],
								[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSString stringWithFormat:@"É uma %@ parcelada", ([[self.transaction valueForKey:@"income"] boolValue] ? @"receita" : @"despesa")], @"rowTitle",
								 @"Text_Left", @"rowType",
								 @"repeat_type", @"columnName",
								 [NSNumber numberWithInt:1], @"rowIndex",
								 [NSNumber numberWithInt:UITableViewCellAccessoryNone], @"rowAccessoryType",
								 [NSNumber numberWithInt:UITableViewCellSelectionStyleGray], @"rowSelectionType",
								 @"parc", @"value",
								 nil],
								nil];
		[self.tableConfig replaceObjectAtIndex:2 withObject:recorrencia];
		recorrencia = nil;
	}

	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"PARCELAMENTO"] != nil) {
		[self.transaction setValue:@"1" forKey:@"repeat_index"];
		[self.transaction setValue:[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PARCELAMENTO"] objectForKey:@"parcelas"] forKey:@"repeat_total"];
	}

	[self.tableView reloadData];

	if (isNewTransaction && [[[self.transaction valueForKey:@"description_text"] description] isEqualToString:@""]) {
		TextAndInput_Cell *cell = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
		UITextField *newTextField = (UITextField *)[cell.contentView viewWithTag:(((1000 * 1) + 1000) + 0)];
		[newTextField becomeFirstResponder];
		newTextField = nil; cell = nil;
	}
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
	return [self.tableConfig count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return (section == [self.tableConfig count] - 1 ? 12 : 0);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return @" ";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	NSInteger returnValue = [[self.tableConfig objectAtIndex:section] count];

	if ([[[[self.tableConfig objectAtIndex:section] objectAtIndex:0] objectForKey:@"columnName"] isEqualToString:@"recurrence_uuid"]) {
		if (![[self.transaction valueForKey:[[[self.tableConfig objectAtIndex:section] objectAtIndex:0] objectForKey:@"columnName"]] boolValue]) {
			return 1;
		}
	}
	
	return returnValue;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	TextAndInput_Cell *cell = (TextAndInput_Cell *)[self.tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil) {
		cell = [[[NSBundle mainBundle] loadNibNamed:@"TextAndInput_Cell" owner:nil options:nil] objectAtIndex:0];
		[cell.input setDelegate:self];
		[cell.input setReturnKeyType:UIReturnKeyNext];
	}

	// Configure the cell...
	if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowType"] isEqualToString:@"Text_Input"]) {
		[cell.separatorLine setHidden:(indexPath.row == [[self.tableConfig objectAtIndex:indexPath.section] count] - 1)];
		[cell setSelectionStyle:[[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowSelectionType"] integerValue]];
		[cell setAccessoryType:[[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowAccessoryType"] integerValue]];

		[cell.label setText:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowTitle"]];

		[cell.type setHidden:YES];
		[cell.detailLabel setHidden:[[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowShowKeyboard"] boolValue]];
		[cell.input setHidden:![[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowShowKeyboard"] boolValue]];
		[cell.input setPlaceholder:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowPlaceholder"]];

		if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowShowKeyboard"] boolValue]) {
			[cell.input setKeyboardType:[[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowKeyboardType"] integerValue]];
		}

		id object = (cell.input.hidden ? (id)cell.detailLabel : (id)cell.input);
		[object setTag:(((1000 * indexPath.section) + 1000) + indexPath.row)];
		[object setTextColor:GRAYOVERWHITECOLOR];

		if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"entityName"] isEqualToString:@""]) {
			if (indexPath.section == 0) {
				BOOL incomeValue = [[self.transaction valueForKey:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"columnName"]] boolValue];
				[object setText:(incomeValue ? @"Receita" : @"Despesa")];
				[cell.type setHidden:NO];
				if (incomeValue) {
					[cell.type setImage:[UIImage imageNamed:@"income@2x.png"]];
				} else {
					[cell.type setImage:[UIImage imageNamed:@"expense@2x.png"]];
				}

			} else {
				NSString *texto = [[self.transaction valueForKey:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"columnName"]] description];
				if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"format"] isEqualToString:@"currency"]) {
					[object setText:[[sharedMethods shared] currencyFormat:texto usingSymbol:@"R$ " andDigits:2]];
				} else if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"format"] isEqualToString:@"date"]) {
					[object setText:[[sharedMethods shared] formattedStringFromString:texto withFormat:@"yyyy-MM-dd" andDisplayFormat:@"dd/MM/yyyy"]];
				} else {
					[object setText:texto];
				}
				texto = nil;
			}

		} else {
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			[fetchRequest setEntity:[NSEntityDescription entityForName:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"entityName"] inManagedObjectContext:self.context]];
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"id == %@", [self.transaction valueForKey:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"predicateColumn"]]]];
			
			for (NSManagedObject *managedObject in [self.context executeFetchRequest:fetchRequest error:nil]) {
				[object setText:[[managedObject valueForKey:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"columnName"]] description]];
			}
			[fetchRequest release]; fetchRequest = nil;
		}

		object = nil;

	} else if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowType"] isEqualToString:@"Text_Switch"]) {
		static NSString *CellIdentifier = @"Text_Switch";
		UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		} else {
			UISwitch *paidSwitch = (UISwitch *)[cell.contentView viewWithTag:[[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowID"] integerValue]];
			[paidSwitch removeFromSuperview];
		}

		[cell.textLabel setText:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowTitle"]];

		int extra = ([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)] ? 15 : 0);
		UISwitch *paidSwitch = [[[UISwitch alloc] initWithFrame: CGRectMake(197 + extra, 9, 94, 27)] autorelease];
		[paidSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
		[paidSwitch setTag:[[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowID"] integerValue]];
		[paidSwitch setOn:[[self.transaction valueForKey:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"columnName"]] boolValue] animated:NO];
		[cell.contentView addSubview:paidSwitch];
		paidSwitch = nil;

		return cell;

	} else if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowType"] isEqualToString:@"Text_Centered"]) {
		static NSString *CellIdentifier = @"Text_Centered";
		UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
		}

		if ([cell respondsToSelector:@selector(setBackgroundView:)]) {
			[cell setBackgroundView:[[[UIImageView alloc] initWithImage:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowBackgroundColor"]] autorelease]];
			[cell setBackgroundColor:[UIColor clearColor]];
		} else {
			[cell setBackgroundColor:[UIColor colorWithPatternImage:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowBackgroundColor"]]];
		}

		[cell.textLabel setText:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowTitle"]];
		[cell.textLabel setTextAlignment:UITextAlignmentCenter];
		[cell.textLabel setTextColor:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowTextColor"]];

		return cell;

	} else if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowType"] isEqualToString:@"Text_Left"]) {
		static NSString *CellIdentifier = @"Text_Left";
		UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		}

		[cell setSelectionStyle:[[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowSelectionType"] integerValue]];
		[cell setAccessoryType:[[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowAccessoryType"] integerValue]];

		[cell.textLabel setText:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowTitle"]];
		[cell.detailTextLabel setText:nil];
		[cell.detailTextLabel setTextColor:GRAYOVERWHITECOLOR];

		if ([[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"columnName"] != nil) {
			if ([[self.transaction valueForKey:@"repeat_total"] integerValue] > 0) {
				NSString *parcelas = @"";
				NSString *period = @"";
				if ([[NSUserDefaults standardUserDefaults] objectForKey:@"PARCELAMENTO"] != nil) {
					NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PARCELAMENTO"];
					parcelas = [dict objectForKey:@"parcelas"];
					period = [dict objectForKey:@"label"];
					dict = nil;
				}

				NSString *value = [self.transaction valueForKey:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"columnName"]];
				if ([value isEqualToString:@"bills"] && [[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowIndex"] integerValue] == 0) {
					[cell setAccessoryType:UITableViewCellAccessoryCheckmark];

					if (![period isEqualToString:@""]) {
						[cell.detailTextLabel setText:[NSString stringWithFormat:@"%@", period]];
					}
				}
				if ([value isEqualToString:@"parc"] && [[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowIndex"] integerValue] == 1) {
					[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
					if (![period isEqualToString:@""]) {
						[cell.detailTextLabel setText:[NSString stringWithFormat:@"Em %@ %@", parcelas, period]];
					}
				}
				value = nil;
				parcelas = nil;
				period = nil;
			}
		}

		return cell;
	}

	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];

	int section = [[self.previousSelectedRow objectForKey:@"section"] integerValue];
	int row = [[self.previousSelectedRow objectForKey:@"row"] integerValue];
	TextAndInput_Cell *cell = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
	UITextField *newTextField = (UITextField *)[cell.contentView viewWithTag:(((1000 * section) + 1000) + row)];
	[newTextField resignFirstResponder];
	newTextField = nil; cell = nil;

	// Last Section/Row
	if (indexPath.section == [self.tableConfig count] - 1) {
		// is to delete
		if ([[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] count] == 4) {
			if (!isNewTransaction && ![[[self.transaction valueForKey:@"recurrence_uuid"] description] isEqualToString:@""]) {
				// Apagar Recorrencias
				int idx = 2;
				UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Esta %@ se repete em outras datas!", ([[self.transaction valueForKey:@"income"] boolValue] ? @"receita" : @"despesa")]
																		  delegate:self
																 cancelButtonTitle:nil
															destructiveButtonTitle:nil
																 otherButtonTitles:@"Apagar somente esta", nil] autorelease];

				if ([[self.transaction valueForKey:@"repeat_index"] integerValue] > 1) {
					[actionSheet addButtonWithTitle:@"Apagar esta e também as próximas"];
					idx++;
				}
				[actionSheet addButtonWithTitle:@"Apagar todas"];
				[actionSheet addButtonWithTitle:@"Cancelar"];
				[actionSheet setCancelButtonIndex:idx];
				[actionSheet setTag:999];
				[actionSheet showInView:self.view];
				actionSheet = nil;
				
			} else {
				UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Organizze"
																 message:[NSString stringWithFormat:@"Tem certeza que deseja apagar esta %@?", ([[self.transaction valueForKey:@"income"] boolValue] ? @"receita" : @"despesa")]
																delegate:self
													   cancelButtonTitle:@"Não"
													   otherButtonTitles:@"Sim", nil] autorelease];
				[alert show]; alert = nil;
			}
		}
	}

	if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowAccessoryType"] integerValue] == UITableViewCellAccessoryDisclosureIndicator) {
		if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"columnName"] isEqualToString:@"date"]) {

			DatePicker_ViewController *anotherViewController = [[[DatePicker_ViewController alloc] initWithNibName:@"DatePicker_ViewController" bundle:nil] autorelease];
			[anotherViewController setTitle:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowTitle"]];
			[anotherViewController setTransaction:self.transaction];
			[self.navigationController pushViewController:anotherViewController animated:YES];
			anotherViewController = nil;

		} else {
			NSArray *moreDataToShow;
			if (indexPath.section == 0) {
				moreDataToShow = [NSArray arrayWithObjects:@"Despesas", @"Receitas", nil];

			} else {
				NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
				[fetchRequest setEntity:[NSEntityDescription entityForName:[[[self.tableConfig objectAtIndex:1] objectAtIndex:indexPath.row] objectForKey:@"entityName"] inManagedObjectContext:self.context]];
				if (indexPath.row == 3) {
					[fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
																								   [NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]],
																								   [NSPredicate predicateWithFormat:@"parent_id == 0"], 
																								   nil]]];
				} else {
					[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]]];
				}

				NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES] autorelease];
				[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
				sortDescriptor = nil;
				
				moreDataToShow = [self.context executeFetchRequest:fetchRequest error:nil];
				[fetchRequest release]; fetchRequest = nil;
			}

			MoreData_TableViewController *anotherViewController = [[[MoreData_TableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
			[anotherViewController setVersaoMais:versaoMais];
			[anotherViewController setTitle:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowTitle"]];
			[anotherViewController setTransaction:self.transaction];
			[anotherViewController setMoreDataToShow:moreDataToShow];
			[anotherViewController setKey:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"columnName"]];
			if (indexPath.row == 3 || indexPath.row == 4) {
				[anotherViewController setKey:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"predicateColumn"]];
			}
			[self.navigationController pushViewController:anotherViewController animated:YES];
			anotherViewController = nil;

			moreDataToShow = nil;
		}
	}

	if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowAccessoryType"] integerValue] == UITableViewCellAccessoryCheckmark ||
		[[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowAccessoryType"] integerValue] == UITableViewCellAccessoryNone) {
		if ([[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"rowSelectionType"] integerValue] == UITableViewCellSelectionStyleGray) {

			NSString *value = [[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"value"];
			[self.transaction setValue:value forKey:[[[self.tableConfig objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"columnName"]];

			Timeframe_ViewController *anotherViewController = [[[Timeframe_ViewController alloc] initWithNibName:@"Timeframe_ViewController" bundle:nil] autorelease];
			[anotherViewController setTitle:[NSString stringWithFormat:@"%@ %@", ([[self.transaction valueForKey:@"income"] boolValue] ? @"Receita" : @"Despesa"), ([value isEqualToString:@"bills"] ? @"Fixa" : @"Parcelada")]];
			[anotherViewController setKind:value];
			[self.navigationController pushViewController:anotherViewController animated:YES];
			anotherViewController = nil;

			value = nil;
		}
	}
}

#pragma mark - UIAlertView Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[self.transaction setValue:[NSDate date] forKey:@"deleted_at"];
		[self.transaction setValue:[NSNumber numberWithBool:NO] forKey:@"synced"];

		// Save the context.
		NSError *error = nil;
		if (![self.context save:&error]) {
			// Replace this implementation with code to handle the error appropriately.
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:@"HASNEWDATA" object:nil];
		[self dismissModalViewControllerAnimated:YES];
	}
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSDictionary *newValues = [NSDictionary dictionaryWithObjectsAndKeys:
							   [[self.transaction valueForKey:@"recurrence_uuid"] description], @"recurrence_uuid",
							   [[self.transaction valueForKey:@"date"] description], @"date",
							   [self.transaction valueForKey:@"repeat_index"], @"repeat_index",
							   [self.transaction valueForKey:@"account_id"], @"account_id",
							   [self.transaction valueForKey:@"tag_id"], @"tag_id",
							   [self.transaction valueForKey:@"income"], @"income",
							   [[self.transaction valueForKey:@"description_text"] description], @"description_text",
							   [self.transaction valueForKey:@"ammount"], @"ammount",
							   [self.transaction valueForKey:@"done"], @"done",
							   //removed mobile_record_id
                               //[self.transaction valueForKey:@"mobile_record_id"], @"mobile_record_id",
							   nil];

	if ([newValues objectForKey:@"description_text"] == [NSNull null] || [[[newValues objectForKey:@"description_text"] description] isEqualToString:@""]) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Organizze"
														 message:@"Preencha o campo Descrição."
														delegate:nil
											   cancelButtonTitle:nil
											   otherButtonTitles:@"Ok", nil] autorelease];
		[alert show]; alert = nil;
		
		TextAndInput_Cell *cell = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
		UITextField *newTextField = (UITextField *)[cell.contentView viewWithTag:(2000 + 0)];
		[newTextField becomeFirstResponder];
		
	} else {

		[self.context rollback];

		BOOL saveAndExit = YES;
		NSString *action = @"all";
		
		NSPredicate *mainPredicate = [NSPredicate predicateWithFormat:@"recurrence_uuid == %@", [newValues objectForKey:@"recurrence_uuid"]];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
		NSPredicate *deletedPredicate = [NSPredicate predicateWithFormat:@"deleted_at == %@", [NSNull null]];

		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.context]];
		[fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:mainPredicate, predicate, deletedPredicate, nil]]];

		NSMutableArray *allObjects = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:fetchRequest error:nil]];
		NSMutableArray *allOtherObjects = [NSMutableArray arrayWithArray:allObjects];

		NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
		if ([buttonTitle isEqualToString:@"Cancelar"]) {
			saveAndExit = NO;
		} else {
			NSRange range;
			range = [buttonTitle rangeOfString:@"somente" options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
			if (range.location != NSNotFound) {
				action = @"actualOnly";
				predicate = [NSPredicate predicateWithFormat:@"date == %@", [self.transaction valueForKey:@"date"]];
			} else {
				range = [buttonTitle rangeOfString:@"próximas" options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
				if (range.location != NSNotFound) {
					action = @"futures";
					if ([[newValues objectForKey:@"repeat_index"] integerValue] > 1) {
						predicate = [NSPredicate predicateWithFormat:@"date >= %@", [self.transaction valueForKey:@"date"]];
					}
				}
			}
		}
		buttonTitle = nil;

		[fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:mainPredicate, predicate, deletedPredicate, nil]]];

		// Edit the sort key as appropriate.
		NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
		[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
		sortDescriptor = nil;

		NSMutableArray *affectedObjects = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:fetchRequest error:nil]];
		[allOtherObjects removeObjectsInArray:affectedObjects];

		if (saveAndExit) {
			[self.navigationItem setLeftBarButtonItem:nil];
			UIActivityIndicatorView *activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
			[activityIndicator setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
			[activityIndicator sizeToFit];
			[activityIndicator startAnimating];
			[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:activityIndicator] autorelease]];
			activityIndicator = nil;
			
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];

			if (actionSheet.tag == 1000) {
				// UPDATE
				NSString *multiplier = @"d";
				int period = 1;
				NSDate *actualDate = [NSDate date];
				NSTimeInterval timeDifference = 0;

				if (![action isEqualToString:@"actualOnly"] && [affectedObjects count] > 1) {
					// Calcular Periodicidade
					NSDate *firstDate = [[sharedMethods shared] dateFromFormattedString:[[[affectedObjects objectAtIndex:0] valueForKey:@"date"] description] usingFormat:@"yyyy-MM-dd"];
					NSDate *secondDate = [[sharedMethods shared] dateFromFormattedString:[[[affectedObjects objectAtIndex:1] valueForKey:@"date"] description] usingFormat:@"yyyy-MM-dd"];
					NSTimeInterval periodicidade = [secondDate timeIntervalSinceDate:firstDate];
					firstDate = nil; secondDate = nil;

					// 1 dia = 24*60*60
					// 1 mes = [28, 29, 30, 31]*24*60*60
					// 1 ano = [~360]*24*60*60
					int qtdadeDias = periodicidade/(24*60*60);
					if (qtdadeDias > 6) {							// Semanal
						period = 7;
						if (qtdadeDias >= 13) {						// Quinzenal
							period = 14;
							if (qtdadeDias > 27) {					// Mensal
								period = 1;
								multiplier = @"M";
								if (qtdadeDias > 2 * 27) {			// Bimestral
									period = 2;
									if (qtdadeDias > 3 * 27) {		// Trimenstral
										period = 3;
										if (qtdadeDias > 6 * 27) {	// Semestral
											period = 6;
											if (qtdadeDias > 300) {	// Anual
												period = 1;
												multiplier = @"y";
											}
										}
									}
								}
							}
						}
					}

					actualDate = [[sharedMethods shared] dateFromFormattedString:[newValues objectForKey:@"date"] usingFormat:@"yyyy-MM-dd"];
					timeDifference = [actualDate timeIntervalSinceDate:self.originalDate];
				}

				NSArray *datas = [NSArray array];
				if (fabs(timeDifference) > 0) {
					NSDate *dateToUse = actualDate;

					NSManagedObject *managedObject = [affectedObjects objectAtIndex:0];
					NSDate *transactionDate = [[sharedMethods shared] dateFromFormattedString:[[managedObject valueForKey:@"date"] description] usingFormat:@"yyyy-MM-dd"];				
					if ([transactionDate compare:actualDate] != NSOrderedSame) {
						dateToUse = [transactionDate dateByAddingTimeInterval:timeDifference];
						NSDateComponents *actualComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSMonthCalendarUnit) fromDate:actualDate];
						NSDateComponents *newComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSMonthCalendarUnit) fromDate:dateToUse];
						if ([newComponents day] != [actualComponents day] && [newComponents month] == [actualComponents month]) {
							[newComponents setDay:[actualComponents day]];
							dateToUse = [[NSCalendar currentCalendar] dateFromComponents:newComponents];
						}
						newComponents = nil; actualComponents = nil;
					}
					transactionDate = nil; managedObject = nil;

					datas = [self generateRecurringDatesStarting:dateToUse
													   forPeriod:[NSDictionary dictionaryWithObjectsAndKeys:multiplier, @"multiplicador", [NSNumber numberWithInt:period], @"tempo", nil]
														andTimes:[affectedObjects count]
												andConsiderFirst:YES];
					dateToUse = nil;
				}

				multiplier = nil;
				actualDate = nil;

				// Atualizar registros
				int idx = 0;
				for (NSManagedObject *managedObject in affectedObjects) {
					[managedObject setValue:[NSDate date] forKey:@"updated_at"];
					[managedObject setValue:[NSNumber numberWithBool:NO] forKey:@"synced"];

                    //removed mobile_record_id
					//[managedObject setValue:[newValues objectForKey:@"mobile_record_id"] forKey:@"mobile_record_id"];

					[managedObject setValue:[newValues objectForKey:@"account_id"] forKey:@"account_id"];
					[managedObject setValue:[newValues objectForKey:@"tag_id"] forKey:@"tag_id"];
					[managedObject setValue:[newValues objectForKey:@"income"] forKey:@"income"];
					[managedObject setValue:[[newValues objectForKey:@"description_text"] description] forKey:@"description_text"];
					[managedObject setValue:[newValues objectForKey:@"ammount"] forKey:@"ammount"];

					if ([datas count] > 0) {
						[managedObject setValue:[[datas objectAtIndex:idx++] objectForKey:@"date"] forKey:@"date"];
					} else if ([action isEqualToString:@"actualOnly"] && [affectedObjects count] == 1) {
						[managedObject setValue:[newValues objectForKey:@"date"] forKey:@"date"];
					}

					//NSDate *transactionDate = [[sharedMethods shared] dateFromFormattedString:[[managedObject valueForKey:@"date"] description] usingFormat:@"yyyy-MM-dd"];				
					//NSDate *currentTransactionDate = [[sharedMethods shared] dateFromFormattedString:[newValues objectForKey:@"date"] usingFormat:@"yyyy-MM-dd"];				
					//if ([transactionDate compare:currentTransactionDate] == NSOrderedSame) {
						[managedObject setValue:[newValues objectForKey:@"done"] forKey:@"done"];
					//}
					//currentTransactionDate = nil; transactionDate = nil;

				}
			}
			
			if (actionSheet.tag == 999) {
				// DELETE
				for (NSManagedObject *managedObject in affectedObjects) {
					[managedObject setValue:[NSDate date] forKey:@"deleted_at"];
				}
				for (NSManagedObject *managedObject in allOtherObjects) {
					if ([[[sharedMethods shared] dateFromFormattedString:[[managedObject valueForKey:@"date"] description] usingFormat:@"yyyy-MM-dd"] compare:[[sharedMethods shared] dateFromFormattedString:[[self.transaction valueForKey:@"date"] description] usingFormat:@"yyyy-MM-dd"]] == NSOrderedDescending) {
						int current = [[[managedObject valueForKey:@"repeat_index"] description] integerValue];
						[managedObject setValue:[NSString stringWithFormat:@"%d", MAX(0, (current - [affectedObjects count]))] forKey:@"repeat_index"];
					}
				}
				for (NSManagedObject *managedObject in allObjects) {
					int total = [[[managedObject valueForKey:@"repeat_total"] description] integerValue];
					[managedObject setValue:[NSString stringWithFormat:@"%d", MAX(0, (total - [affectedObjects count]))] forKey:@"repeat_total"];			
					[managedObject setValue:[NSDate date] forKey:@"updated_at"];
					[managedObject setValue:[NSNumber numberWithBool:NO] forKey:@"synced"];
				}
			}
		}

		allOtherObjects = nil; affectedObjects = nil; allObjects = nil;
		mainPredicate = nil; predicate = nil; deletedPredicate = nil;
		[fetchRequest release]; fetchRequest = nil;

		if (saveAndExit) {
			NSError *error = nil;
			if (![self.context save:&error]) {
				// Replace this implementation with code to handle the error appropriately.
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"HASNEWDATA" object:nil];
			[self dismissModalViewControllerAnimated:YES];
		}
	}

	newValues = nil;
}

#pragma mark - Keyboard methods

// Tratar aparencia do teclado e visibilidade
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	// Obter a SECTION e ROW do campo
	int section = (int)(textField.tag - 1000)/1000;
	int row = (int)fmod(textField.tag - 1000, 1000);

	if (section < 0) {
		return NO;
	}

	BOOL returnValue = [[[[self.tableConfig objectAtIndex:section] objectAtIndex:row] objectForKey:@"rowShowKeyboard"] boolValue];
	if (returnValue) {
		self.previousSelectedRow = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:section], @"section", [NSNumber numberWithInt:row], @"row", nil];
		if (keyboardIsVisible) {
			[self addButtonToKeyboard];
		}
	} else {
		if (self.previousSelectedRow != nil) {
			int section = [[self.previousSelectedRow objectForKey:@"section"] integerValue];
			int row = [[self.previousSelectedRow objectForKey:@"row"] integerValue];
			TextAndInput_Cell *cell = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
			UITextField *newTextField = (UITextField *)[cell.contentView viewWithTag:(((1000 * section) + 1000) + row)];
			[newTextField resignFirstResponder];
			newTextField = nil; cell = nil;
		}
	}

	return returnValue;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	if (textField.tag == 2001) {
		[textField setText:[[sharedMethods shared] currencyFormat:@"0" usingSymbol:@"R$ " andDigits:2]];
		return NO;
	}
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (textField.tag == 2001) {
		if ([textField.text isEqualToString:@""]) {
			[textField setText:[[sharedMethods shared] currencyFormat:@"0" usingSymbol:@"R$ " andDigits:2]];
			range.location = [textField.text length];
		}
		NSMutableString *field_text = [NSMutableString stringWithString:textField.text];
		[field_text replaceCharactersInRange:range withString:string];
		
		[textField setText:[[sharedMethods shared] currencyFormat:[self unformatString:field_text] usingSymbol:@"R$ " andDigits:2]];

		NSDecimalNumber *amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:[self unformatString:field_text]];
		[self.transaction setValue:amount forKey:@"ammount"];
		amount = nil;

		return NO;
	}
	return YES;
}

- (NSString *)unformatString:(NSMutableString *)string {
	[string setString:[string stringByReplacingOccurrencesOfString:@"." withString:@""]];
	[string setString:[string stringByReplacingOccurrencesOfString:@"," withString:@""]];
	[string setString:[string stringByReplacingOccurrencesOfString:@"R$ " withString:@""]];
	
	NSMutableString *filtered_string = [NSMutableString stringWithString:string];
	NSMutableString *return_string = [NSMutableString string];
	for (NSUInteger i = 0; i < [filtered_string length]; i++) {
		NSString *target_str = [filtered_string substringWithRange:(NSRange){i, 1}];
		if (i == [filtered_string length] - 2) [return_string appendFormat:@".%@", target_str];
		else [return_string appendString:target_str];
	}
	
	return return_string;
}

// Tratar comportamento da tecla ENTER
- (BOOL)textFieldShouldReturn:(UITextField *)textField {	
	[textField resignFirstResponder];
	
	// Obter a SECTION e ROW do campo
	int section = (int)(textField.tag - 1000)/1000;
	int row = (int)fmod(textField.tag - 1000, 1000);
	
	if (section == 1) {
		if (row == 0) {
			[self.transaction setValue:textField.text forKey:@"description_text"];
		}
		
		row++;
		TextAndInput_Cell *cell = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
		UITextField *newTextField = (UITextField *)[cell.contentView viewWithTag:(((1000 * section) + 1000) + row)];
		[newTextField becomeFirstResponder];
		newTextField = nil; cell = nil;
	}

	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	[textField resignFirstResponder];

	if (!hasCanceled) {
		// Obter a SECTION e ROW do campo
		int section = (int)(textField.tag - 1000)/1000;
		int row = (int)fmod(textField.tag - 1000, 1000);
		
		if (section == 1) {
			if (row == 0) {
				[self.transaction setValue:textField.text forKey:@"description_text"];
			}
		}
	}

	return YES;
}

- (void)doneButton:(id)sender {
	TextAndInput_Cell *cell = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
	UITextField *newTextField = (UITextField *)[cell.contentView viewWithTag:(((1000 * 1) + 1000) + 1)];
	[newTextField resignFirstResponder];
	newTextField = nil; cell = nil;
}

- (void)addButtonToKeyboard {
	int section = [[self.previousSelectedRow objectForKey:@"section"] integerValue];
	int row = [[self.previousSelectedRow objectForKey:@"row"] integerValue];

	// create custom button
	UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[doneButton setFrame:CGRectMake(0, 163, 105, 53)];
	[doneButton setAdjustsImageWhenHighlighted:NO];
	[doneButton setTitle:@"Ok" forState:UIControlStateNormal];
	[doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	[doneButton setBackgroundImage:[UIImage imageNamed:@"DoneUp.png"] forState:UIControlStateNormal];
	[doneButton setBackgroundImage:[UIImage imageNamed:@"DoneDown.png"] forState:UIControlStateHighlighted];
	[doneButton addTarget:self action:@selector(doneButton:) forControlEvents:UIControlEventTouchUpInside];
	
	// locate keyboard view
	UIWindow *tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:1];
	UIView *keyboard;
	for (int i = 0; i < [tempWindow.subviews count]; i++) {
		keyboard = [tempWindow.subviews objectAtIndex:i];
		
		for (UIButton *btn in [keyboard subviews]) {
			if ([btn isKindOfClass:[UIButton class]]) {
				[btn removeFromSuperview];
			}
		}
		
		if ([[[[self.tableConfig objectAtIndex:section] objectAtIndex:row] objectForKey:@"rowKeyboardType"] integerValue] == UIKeyboardTypeNumberPad) {
			// keyboard found, add the button
			if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
				if([[keyboard description] hasPrefix:@"<UIPeripheralHost"] == YES)
					[keyboard addSubview:doneButton];
			} else {
				if([[keyboard description] hasPrefix:@"<UIKeyboard"] == YES)
					[keyboard addSubview:doneButton];
			}
		}
	}
	keyboard = nil; tempWindow = nil;
	doneButton = nil;
} 

- (void)keyboardWillShow:(NSNotification *)note {
	// if clause is just an additional precaution, you could also dismiss it
	if ([[[UIDevice currentDevice] systemVersion] floatValue] < 3.2) {
		keyboardIsVisible = YES;
		[self addButtonToKeyboard];
	}
}

- (void)keyboardDidShow:(NSNotification *)note {
	// if clause is just an additional precaution, you could also dismiss it
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
		keyboardIsVisible = YES;
		[self addButtonToKeyboard];
    }
}

#pragma mark - View Methods

- (IBAction)switchChanged:(id)sender {
	int section = [[self.previousSelectedRow objectForKey:@"section"] integerValue];
	int row = [[self.previousSelectedRow objectForKey:@"row"] integerValue];
	TextAndInput_Cell *cell = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
	UITextField *newTextField = (UITextField *)[cell.contentView viewWithTag:(((1000 * section) + 1000) + row)];
	[newTextField resignFirstResponder];
	newTextField = nil; cell = nil;

	UISwitch *mySwitch = (UISwitch *)sender;
	if (mySwitch.tag == 999) {
		[self.transaction setValue:[NSNumber numberWithBool:![[self.transaction valueForKey:@"done"] boolValue]] forKey:@"done"];
	}

	if (mySwitch.tag == 1000) {
		if ([mySwitch isOn]) {
			[self.transaction setValue:[[sharedMethods shared] generateUUID] forKey:@"recurrence_uuid"];
		} else {
			[self.transaction setValue:@"" forKey:@"recurrence_uuid"];
			[self.transaction setValue:@"0" forKey:@"repeat_total"];
			[self.transaction setValue:@"0" forKey:@"repeat_index"];
			[self.transaction setValue:@"bills" forKey:@"repeat_type"];
		}
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.4f), dispatch_get_current_queue(), ^{
			[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self.tableConfig count]-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
		});

	}
	mySwitch = nil;
}

- (void)cancel {
	hasCanceled = YES;

	if ([self.context hasChanges]) {
		if (isNewTransaction) {
			[self.context deleteObject:self.transaction];
		} else {
			[self.context rollback];
		}

		NSError *error = nil;
		if (![self.context save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		}		
	}

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.05f), dispatch_get_current_queue(), ^{
		[self dismissModalViewControllerAnimated:YES];
	});
}

- (void)save {
	for (int row = 0; row < 2; row++) {
		TextAndInput_Cell *cell = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
		UITextField *newTextField = (UITextField *)[cell.contentView viewWithTag:(2000 + row)];
		[newTextField resignFirstResponder];
		if (row == 0) {
			if (![newTextField.text isEqualToString:[[self.transaction valueForKey:@"description_text"] description]]) {
				[self.transaction setValue:newTextField.text forKey:@"description_text"];
			}
		}
		newTextField = nil; cell = nil;
	}

	if ([self.transaction valueForKey:@"description_text"] == [NSNull null] || [[[self.transaction valueForKey:@"description_text"] description] isEqualToString:@""]) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Organizze"
														 message:@"Preencha o campo Descrição."
														delegate:nil
											   cancelButtonTitle:nil
											   otherButtonTitles:@"Ok", nil] autorelease];
		[alert show]; alert = nil;

		TextAndInput_Cell *cell = (TextAndInput_Cell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
		UITextField *newTextField = (UITextField *)[cell.contentView viewWithTag:(2000 + 0)];
		[newTextField becomeFirstResponder];

	} else {
		// Save the context.
		if ([self.context hasChanges]) {
			if (!isNewTransaction && ![[[self.transaction valueForKey:@"recurrence_uuid"] description] isEqualToString:@""]) {
				// Alterar Recorrencia
				int idx = 2;
				UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Esta %@ se repete em outras datas!", ([[self.transaction valueForKey:@"income"] boolValue] ? @"receita" : @"despesa")]
																		  delegate:self
																 cancelButtonTitle:nil
															destructiveButtonTitle:nil
																 otherButtonTitles:@"Alterar somente esta", nil] autorelease];
				
				if ([[self.transaction valueForKey:@"repeat_index"] integerValue] > 1) {
					[actionSheet addButtonWithTitle:@"Alterar esta e também as próximas"];
					idx++;
				}
				[actionSheet addButtonWithTitle:@"Alterar todas"];
				[actionSheet addButtonWithTitle:@"Cancelar"];
				[actionSheet setCancelButtonIndex:idx];
				[actionSheet setTag:1000];
				[actionSheet showInView:self.view];
				actionSheet = nil;

			} else {
				[self.navigationItem setLeftBarButtonItem:nil];
				UIActivityIndicatorView *activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
				[activityIndicator setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
				[activityIndicator sizeToFit];
				[activityIndicator startAnimating];
				[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:activityIndicator] autorelease]];
				activityIndicator = nil;

				[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];

				// Criar Transacoes (novas e recorrentes)
				[self.transaction setValue:[NSDate date] forKey:@"updated_at"];
				[self.transaction setValue:[NSNumber numberWithBool:NO] forKey:@"synced"];

				if (![[[self.transaction valueForKey:@"recurrence_uuid"] description] isEqualToString:@""]) {
					if ([[NSUserDefaults standardUserDefaults] objectForKey:@"PARCELAMENTO"] != nil) {
						NSArray *datas = [self generateRecurringDatesStarting:[[sharedMethods shared] dateFromFormattedString:[[self.transaction valueForKey:@"date"] description] usingFormat:@"yyyy-MM-dd"]
																	forPeriod:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PARCELAMENTO"]
																	 andTimes:[[self.transaction valueForKey:@"repeat_total"] integerValue]
															 andConsiderFirst:NO];

						// Se houver recorrencia, criar as entradas
						for (int i = 1; i < [[self.transaction valueForKey:@"repeat_total"] integerValue]; i++) {
							NSEntityDescription *recorrentTransaction = [NSEntityDescription insertNewObjectForEntityForName:@"Transactions" inManagedObjectContext:self.context];
							[recorrentTransaction setValue:[[sharedMethods shared] generateUUID] forKey:@"uuid"];

							[recorrentTransaction setValue:[self.transaction valueForKey:@"tag_id"] forKey:@"tag_id"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"account_id"] forKey:@"account_id"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"user_id"] forKey:@"user_id"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"created_at"] forKey:@"created_at"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"updated_at"] forKey:@"updated_at"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"income"] forKey:@"income"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"ammount"] forKey:@"ammount"];
							[recorrentTransaction setValue:[[self.transaction valueForKey:@"description_text"] description] forKey:@"description_text"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"start_result"] forKey:@"start_result"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"transfer"] forKey:@"transfer"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"synced"] forKey:@"synced"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"repeat_total"] forKey:@"repeat_total"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"repeat_type"] forKey:@"repeat_type"];
							[recorrentTransaction setValue:[NSString stringWithFormat:@"%d", i + 1] forKey:@"repeat_index"];
							[recorrentTransaction setValue:[self.transaction valueForKey:@"recurrence_uuid"] forKey:@"recurrence_uuid"];

							[recorrentTransaction setValue:[[datas objectAtIndex:i] objectForKey:@"date"] forKey:@"date"];
							[recorrentTransaction setValue:[[datas objectAtIndex:i] objectForKey:@"done"] forKey:@"done"];

							NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
							[fetchRequest setEntity:[NSEntityDescription entityForName:@"Transactions" inManagedObjectContext:self.context]];
							//removed mobile_record_id
                            //[recorrentTransaction setValue:[NSNumber numberWithInt:[[self.context executeFetchRequest:fetchRequest error:nil] count]] forKey:@"mobile_record_id"];
							[fetchRequest release]; fetchRequest = nil;

							recorrentTransaction = nil;
						}
						datas = nil;

					} else {
						[self.transaction setValue:@"" forKey:@"recurrence_uuid"];	
					}
				}

				NSError *error = nil;
				if (![self.context save:&error]) {
					// Replace this implementation with code to handle the error appropriately.
					NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				}

				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.05f), dispatch_get_current_queue(), ^{
					[[NSNotificationCenter defaultCenter] postNotificationName:@"HASNEWDATA" object:nil];
					[self dismissModalViewControllerAnimated:YES];
				});
			}
		}
	}
}

- (NSArray *)generateRecurringDatesStarting:(NSDate *)initialDate forPeriod:(NSDictionary *)period andTimes:(int)repeat andConsiderFirst:(BOOL)usesFirst {
	int periodo = [[period objectForKey:@"tempo"] integerValue];
	NSString *multiplier = [period objectForKey:@"multiplicador"];
	NSDateComponents *originalComponents = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:initialDate];
	NSMutableArray *localArray = [NSMutableArray array];
	int startIndex = 0;
	if (!usesFirst) {
		startIndex = 1;
		[localArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"date", @"", @"done", nil]];		// index 0
	}

	for (int i = startIndex; i < repeat; i++) {
		// Baseado na periodidade, alterar a data da transacao
		NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:initialDate];
		if ([multiplier isEqualToString:@"d"]) {
			[components setDay:([components day] + (periodo * i))];
		} else if ([multiplier isEqualToString:@"M"]) {
			[components setMonth:([components month] + (periodo * i))];
		} else if ([multiplier isEqualToString:@"y"]) {
			[components setYear:([components year] + (periodo * i))];
		}
		
		NSDate *newDate = [[NSCalendar currentCalendar] dateFromComponents:components];
		components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
		if ([multiplier isEqualToString:@"M"] || [multiplier isEqualToString:@"y"]) {
			if ([components day] != [originalComponents day]) {
				[components setDay:0];
			}
		}
		newDate = [[NSCalendar currentCalendar] dateFromComponents:components];
		
		components = nil;

		[localArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   [[sharedMethods shared] formattedStringFromDate:newDate usingFormat:@"yyyy-MM-dd"], @"date", 
							   [NSNumber numberWithBool:([newDate compare:[NSDate date]] == NSOrderedAscending)], @"done", nil]];

		newDate = nil;
	}
	originalComponents = nil;
	multiplier = nil;

	return [NSArray arrayWithArray:localArray];
}

@end
