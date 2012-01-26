//
//  MoreData_TableViewController.h
//  Organizze
//
//  Created by Cassio Rossi on 05/09/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

@interface MoreData_TableViewController : UITableViewController {
	NSArray					*moreDataToShow, *childrenArray;
	NSManagedObject			*transaction;
	NSString				*key;
	BOOL					 versaoMais;
}

@property (nonatomic, retain) NSArray *moreDataToShow, *childrenArray;
@property (nonatomic, retain) NSManagedObject *transaction;
@property (nonatomic, retain) NSString *key;
@property BOOL versaoMais;

- (void)cancel;

@end
