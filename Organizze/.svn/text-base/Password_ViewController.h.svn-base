//
//  Password_ViewController.h
//  Organizze
//
//  Created by Cassio Rossi on 11/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

@interface Password_ViewController : UIViewController <UITextFieldDelegate> {
	UITextField	*code1, *code2, *code3, *code4, *passcode;
	UILabel		*messageLabel;
	NSString	*password;
	int			 qtdadePedidoSenha;
}

@property (nonatomic, assign) IBOutlet UILabel *messageLabel;
@property (nonatomic, assign) IBOutlet UITextField *code1, *code2, *code3, *code4, *passcode;
@property (nonatomic, retain) NSString *password;
@property BOOL askForPassword;

- (void)limitTextField:(NSNotification *)note;
- (void)setMessageLabelText:(NSString *)text forError:(BOOL)error;
- (void)exitPasswordController;

@end
