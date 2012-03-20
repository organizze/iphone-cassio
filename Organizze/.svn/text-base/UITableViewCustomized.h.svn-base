//
//  UITableViewCustomized.h
//  Organizze
//
//  Created by Cassio Rossi on 25/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#define HORIZ_SWIPE_DRAG_MIN 100

@protocol UITableViewCustomizedDelegate <UITableViewDelegate>
@optional
- (void)moveToPreviousItem;
- (void)moveToNextItem;

@end

@interface UITableViewCustomized : UITableView {
	id <UITableViewCustomizedDelegate> delegate;

	CGPoint 	mystartTouchPosition;
	BOOL 		isProcessingListMove;
}

@property (nonatomic, assign) id <UITableViewCustomizedDelegate> delegate;

@end
