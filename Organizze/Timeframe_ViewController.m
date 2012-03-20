//
//  Timeframe_ViewController.m
//  Organizze
//
//  Created by Cassio Rossi on 05/09/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "Timeframe_ViewController.h"

@implementation Timeframe_ViewController

#pragma mark - @synthesize

@synthesize picker, data, dataToShow, kind;

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

	[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"fundo_claro.png"]]];

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

	NSArray *labels = [NSArray arrayWithObjects:@"dias", @"semanas", @"meses", @"bimestres", @"trimestres", @"semestres", @"anos", nil];
	NSArray *values = [NSArray arrayWithObjects:@"1", @"7", @"1", @"2", @"3", @"6", @"1", nil];
	NSArray *multiplier = [NSArray arrayWithObjects:@"d", @"d", @"M", @"M", @"M", @"M", @"y", nil];
	NSArray *max = [NSArray arrayWithObjects:@"360", @"260", @"60", @"30", @"20", @"10", @"5", nil];

	if ([self.kind isEqualToString:@"bills"]) {
		labels = [NSArray arrayWithObjects:@"Semanal", @"Quinzenal", @"Mensal", @"Bimestral", @"Trimestral", @"Semestral", @"Anual", nil];
		values = [NSArray arrayWithObjects:@"7", @"14", @"1", @"2", @"3", @"6", @"1", nil];
		multiplier = [NSArray arrayWithObjects:@"d", @"d", @"M", @"M", @"M", @"M", @"y", nil];
	}
	
	self.data = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:labels, values, multiplier, max, nil] forKeys:[NSArray arrayWithObjects:@"labels", @"values", @"multiplier", @"max", nil]];
	if (![self.kind isEqualToString:@"bills"]) {
		[self.dataToShow addObject:[NSArray arrayWithObject:@"Parcelas"]];
	}
	self.dataToShow = [NSMutableArray arrayWithArray:[self.data valueForKey:@"labels"]];

	parcelas = 60;
	indexPeriod = 2;
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

	[self.picker selectRow:indexPeriod inComponent:([self.kind isEqualToString:@"bills"] ? 0 : 1) animated:YES];

	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"PARCELAMENTO"] != nil) {
		NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PARCELAMENTO"];
		parcelas = [[dict objectForKey:@"parcelas"] integerValue];
		indexPeriod = [self.dataToShow indexOfObject:[dict objectForKey:@"label"]];
		dict = nil;

		if ([self.kind isEqualToString:@"bills"]) {
			[self.picker selectRow:indexPeriod inComponent:0 animated:YES];
		} else {
			[self.picker selectRow:(parcelas - 1) inComponent:0 animated:YES];
			[self.picker selectRow:indexPeriod inComponent:1 animated:YES];
		}
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

#pragma mark - View Methods

- (void)cancel {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PARCELAMENTO"];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[self.navigationController popViewControllerAnimated:YES];
}

- (void)save {
	[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:
													  [NSString stringWithFormat:@"%d", parcelas], @"parcelas", 
													  [[self.data objectForKey:@"labels"] objectAtIndex:indexPeriod], @"label", 
													  [[self.data objectForKey:@"values"] objectAtIndex:indexPeriod], @"tempo", 
													  [[self.data objectForKey:@"multiplier"] objectAtIndex:indexPeriod], @"multiplicador", nil] 
											  forKey:@"PARCELAMENTO"];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Picker Data Source Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return ([self.kind isEqualToString:@"bills"] ? 1 : 2);
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	NSInteger returnValue = 0;

	if ([self.kind isEqualToString:@"bills"] || component == 1) {
		returnValue = [self.dataToShow count];
	} else {
		returnValue = [[[self.data objectForKey:@"max"] objectAtIndex:indexPeriod] integerValue];
	}

	return returnValue;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	NSString *returnTitle = @"";
	
	if ([self.kind isEqualToString:@"bills"] || component == 1) {
		returnTitle = [self.dataToShow objectAtIndex:row];
	} else {
		returnTitle = [NSString stringWithFormat:@"%d", row + 1];
	}
	
	return returnTitle;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	if ([self.kind isEqualToString:@"bills"]) {
		indexPeriod = row;
		parcelas = [[[self.data objectForKey:@"max"] objectAtIndex:row] integerValue];
	} else if (component == 1) {
		indexPeriod = row;
		[self.picker reloadComponent:0];
		parcelas = MIN(parcelas, [[[self.data objectForKey:@"max"] objectAtIndex:row] integerValue]);
	} else {
		parcelas = row + 1;
	}	
}

@end
