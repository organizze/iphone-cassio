//
//  UITableViewCustomized.m
//  Organizze
//
//  Created by Cassio Rossi on 25/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "UITableViewCustomized.h"

@implementation UITableViewCustomized

#pragma mark - @synthesize

@synthesize delegate;

#pragma mark - View Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint newTouchPosition = [touch locationInView:self];
	if (mystartTouchPosition.x != newTouchPosition.x || mystartTouchPosition.y != newTouchPosition.y) {
		isProcessingListMove = NO;
	}
	mystartTouchPosition = [touch locationInView:self];
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = touches.anyObject;
	CGPoint currentTouchPosition = [touch locationInView:self];
	
	// If the swipe tracks correctly.
	double diffx = mystartTouchPosition.x - currentTouchPosition.x + 0.1; // adding 0.1 to avoid division by zero
	double diffy = mystartTouchPosition.y - currentTouchPosition.y + 0.1; // adding 0.1 to avoid division by zero
	
	if(abs(diffx / diffy) > 1 && abs(diffx) > HORIZ_SWIPE_DRAG_MIN) {
		// It appears to be a swipe.
		if (isProcessingListMove) {
			// ignore move, we're currently processing the swipe
			return;
		}
		
		if (mystartTouchPosition.x < currentTouchPosition.x) {
			isProcessingListMove = YES;
			if (delegate && [delegate respondsToSelector:@selector(moveToPreviousItem)]) {
				[delegate moveToPreviousItem];
			}
			return;
		} else {
			isProcessingListMove = YES;
			if (delegate && [delegate respondsToSelector:@selector(moveToNextItem)]) {
				[delegate moveToNextItem];
			}
			return;
		}
	} else if(abs(diffy / diffx) > 1) {
		isProcessingListMove = YES;
		[super touchesMoved:touches	withEvent:event];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!isProcessingListMove) {
		UITouch *touch = [touches anyObject];
		NSIndexPath *indexPath = [self indexPathForRowAtPoint:[touch locationInView:self]];
		if (touch.tapCount == 1 && indexPath) {
			if (delegate && [delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
				[delegate tableView:self didSelectRowAtIndexPath:indexPath];
			}
		}
	}

	isProcessingListMove = NO;
	[super touchesEnded:touches withEvent:event];
}

@end
