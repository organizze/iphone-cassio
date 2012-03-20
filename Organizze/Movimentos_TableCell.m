//
//  Movimentos_TableCell.m
//  Organizze
//
//  Created by Cassio Rossi on 22/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "Movimentos_TableCell.h"

@implementation Movimentos_TableCell

@synthesize movimento, valor, categoria, pago, tag, background;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		// Initialization code
	}
	return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	// Configure the view for the selected state
}

@end
