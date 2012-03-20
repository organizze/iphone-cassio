//
//  Password_ViewController.m
//  Organizze
//
//  Created by Cassio Rossi on 11/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "Password_ViewController.h"
#import "SFHFKeychainUtils.h"
#import "AppDelegate.h"

@implementation Password_ViewController

#pragma mark - @synthesize

@synthesize code1, code2, code3, code4, passcode, messageLabel;
@synthesize password;
@synthesize askForPassword;

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UITextFieldTextDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];		
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];		

    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

	// Do any additional setup after loading the view from its nib.	
	[self setMessageLabelText:@"Digitar Código" forError:NO];

	//Tratar ações do teclado
	//Tratar ações do teclado
	[self.passcode setDelegate:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(limitTextField:) name:@"UITextFieldTextDidChangeNotification" object:self.passcode];

	if (askForPassword) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];		
	}

}

- (void)viewDidUnload {
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	[self.passcode becomeFirstResponder];
	self.password = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Keyboard methods

- (void)doneButton:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)addButtonToKeyboard {
	// create custom button
	UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[doneButton setFrame:CGRectMake(0, 163, 105, 53)];
	[doneButton setAdjustsImageWhenHighlighted:NO];
	[doneButton setTitle:@"Cancelar" forState:UIControlStateNormal];
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
		// keyboard found, add the button
		if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
			if([[keyboard description] hasPrefix:@"<UIPeripheralHost"] == YES)
				[keyboard addSubview:doneButton];
		} else {
			if([[keyboard description] hasPrefix:@"<UIKeyboard"] == YES)
				[keyboard addSubview:doneButton];
		}
	}
	doneButton = nil; keyboard = nil; tempWindow = nil;
} 

- (void)keyboardWillShow:(NSNotification *)note {
	// if clause is just an additional precaution, you could also dismiss it
	if ([[[UIDevice currentDevice] systemVersion] floatValue] < 3.2) {
		[self addButtonToKeyboard];
	}
}

- (void)keyboardDidShow:(NSNotification *)note {
	// if clause is just an additional precaution, you could also dismiss it
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
		[self addButtonToKeyboard];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if ([string length] == 1) {
		switch ([textField.text length]) {
			case 0: {
				[self.code1 setText:string];
			} break;
			case 1: {
				[self.code2 setText:string];
			} break;
			case 2: {
				[self.code3 setText:string];
			} break;
			case 3: {
				[self.code4 setText:string];
			} break;
			default:
				break;
		}
	} else {
		switch (textField.text.length - 1) {
			case 0: {
				[self.code1 setText:string];
			} break;
			case 1: {
				[self.code2 setText:string];
			} break;
			case 2: {
				[self.code3 setText:string];
			} break;
			case 3: {
				[self.code4 setText:string];
			} break;
			default:
				break;
		}
	}

	return ([textField.text length] <= 3 || [string length] != 1);
}

- (void)limitTextField:(NSNotification *)note {
	if ([self.passcode.text length] > 3) {
		if (askForPassword) {
			
			if ([self.passcode.text caseInsensitiveCompare:self.password] == NSOrderedSame) {
				// Store password
				[SFHFKeychainUtils storeUsername:@"organizze" andPassword:self.password forServiceName:@"omz:software Organizze" updateExisting:YES error:NULL];
				[self exitPasswordController];
			} else {
				[self setMessageLabelText:@"Digitar novamente" forError:NO];

				self.password = self.passcode.text;
				[self.code1 setText:@""];
				[self.code2 setText:@""];
				[self.code3 setText:@""];
				[self.code4 setText:@""];
				[self.passcode setText:nil];
				qtdadePedidoSenha++;
				if (qtdadePedidoSenha > 1) {
					self.password = nil;
					qtdadePedidoSenha = 0;
					[self setMessageLabelText:@"Os códigos não coincidem\nTentar novamente" forError:YES];
				}
			}
			
		} else {
			
			self.password = [SFHFKeychainUtils getPasswordForUsername:@"organizze" andServiceName:@"omz:software Organizze" error:NULL];
			if ([self.passcode.text caseInsensitiveCompare:self.password] != NSOrderedSame) {
				[self setMessageLabelText:@"Senha Incorreta\nTentar novamente" forError:YES];
				
				[self.code1 setText:@""];
				[self.code2 setText:@""];
				[self.code3 setText:@""];
				[self.code4 setText:@""];
				[self.passcode setText:nil];
			} else {
				[self exitPasswordController];
			}
			
		}
	}
}

- (void)setMessageLabelText:(NSString *)text forError:(BOOL)error {
	[self.messageLabel setText:text];
	[self.messageLabel setFont:[UIFont boldSystemFontOfSize:(error ? 18: 22)]];
	[self.messageLabel setTextColor:(error ? REDCOLOR : GRAYOVERWHITECOLOR)];
}

#pragma mark - View Methods

- (void)exitPasswordController {
	[self setMessageLabelText:@"" forError:NO];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3f), dispatch_get_current_queue(), ^{
		[self.passcode resignFirstResponder];
		
		if (askForPassword) {
			[self dismissModalViewControllerAnimated:YES];
		} else {
			[(AppDelegate *)[[UIApplication sharedApplication] delegate] initializeApp];
		}
	});
}

@end
