//
//  TextAndInput_Cell.m
//  Organizze
//
//  Created by Cassio Rossi on 16/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "TextAndInput_Cell.h"

@implementation TextAndInput_Cell

@synthesize label, detailLabel, separatorLine, input, type;

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
