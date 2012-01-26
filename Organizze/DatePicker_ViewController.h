//
//  DatePicker_ViewController.h
//  Organizze
//
//  Created by Cassio Rossi on 05/09/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

@interface DatePicker_ViewController : UIViewController {
	NSManagedObject		*transaction;
	UIDatePicker		*datePicker;
}

@property (nonatomic, retain) NSManagedObject *transaction;
@property (nonatomic, assign) IBOutlet UIDatePicker *datePicker;

- (void)cancel;
- (void)save;

@end
