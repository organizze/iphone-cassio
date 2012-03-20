//
//  Login_ViewController.h
//  Organizze
//
//  Created by Cassio Rossi on 11/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "parser.h"

@interface Login_ViewController : UITableViewController <UITextFieldDelegate, parserDelegate> {
	BOOL		 firstTime;
	NSString	*key, *transfer, *transfer_month;
}

@property BOOL firstTime;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSString *key, *transfer, *transfer_month;

- (void)showSyncMessage:(BOOL)show;
- (void)back;
- (void)reposicionarView;
- (void)doLogin;

@end
