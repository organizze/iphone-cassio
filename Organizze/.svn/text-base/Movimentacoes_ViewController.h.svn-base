//
//  Movimentacoes_ViewController.h
//  Organizze
//
//  Created by Cassio Rossi on 11/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "parser.h"
#import "Movimentos_TableCell.h"
//#import "UITableViewCustomized.h"

@interface Movimentacoes_ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, parserDelegate> {
	Movimentos_TableCell	*movimentosCell;
	UITableView				*tableView;
	UIView					*resumeView, *detailsView, *previousView, *noDataView, *tooltipView;
	UILabel					*headerLabel, *footerLabel, *incomeLabel, *expenseLabel, *previousLabel, *saldoInicial;
	int						 months;
	NSString				*currentMonth;
	BOOL					 shouldChangeMonth, isProcessingListMove, downOrientation, abortSync;
	CGPoint 				 mystartTouchPosition;
	UIImageView				*arrow;
}

@property (nonatomic, assign) IBOutlet Movimentos_TableCell *movimentosCell;
@property (nonatomic, assign) IBOutlet UITableView *tableView;
@property (nonatomic, assign) IBOutlet UIView *resumeView, *detailsView, *previousView, *noDataView, *tooltipView;
@property (nonatomic, assign) IBOutlet UILabel *headerLabel, *footerLabel, *incomeLabel, *expenseLabel, *previousLabel, *saldoInicial;
@property (nonatomic, assign) NSString *currentMonth;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) IBOutlet UIImageView *arrow;

- (void)configureCell:(Movimentos_TableCell *)cell atIndexPath:(NSIndexPath *)indexPath;

- (void)sleepAndExit;
- (void)exit;

- (void)showSyncMessage:(BOOL)show;
- (void)showConfig;
- (void)synchronizeData;
- (void)addRecord:(id)sender;

- (void)setNewDate;
- (IBAction)previousMonth:(id)sender;
- (IBAction)nextMonth:(id)sender;
- (void)updateDetailView;
- (void)showHideDetailView;

- (void)moveToPreviousItem;
- (void)moveToNextItem;

- (NSDecimalNumber *)getInitialAmmount;

@end
