//
//  AddMovimento_TableViewController.h
//  Organizze
//
//  Created by Cassio Rossi on 30/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

@interface AddMovimento_TableViewController : UITableViewController <UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
	NSManagedObjectContext	*context;
	NSManagedObject			*transaction;
	NSMutableArray			*tableConfig;
	NSDictionary			*previousSelectedRow;
	BOOL					 isNewTransaction, keyboardIsVisible, versaoMais, hasCanceled;
	NSString				*currentMonth;
	NSDate					*originalDate;
}

@property (nonatomic, retain) NSManagedObjectContext *context;
@property (nonatomic, retain) NSManagedObject *transaction;
@property (nonatomic, retain) NSMutableArray *tableConfig;
@property (nonatomic, retain) NSDictionary *previousSelectedRow;
@property (nonatomic, retain) NSString *currentMonth;
@property (nonatomic, retain) NSDate *originalDate;

- (IBAction)switchChanged:(id)sender;
- (void)cancel;
- (void)save;
- (NSString *)unformatString:(NSMutableString *)string;
- (void)addButtonToKeyboard;
- (NSArray *)generateRecurringDatesStarting:(NSDate *)initialDate forPeriod:(NSDictionary *)period andTimes:(int)repeat andConsiderFirst:(BOOL)usesFirst;

@end
