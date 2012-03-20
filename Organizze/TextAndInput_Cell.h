//
//  TextAndInput_Cell.h
//  Organizze
//
//  Created by Cassio Rossi on 16/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

@interface TextAndInput_Cell : UITableViewCell {
	UILabel		*label, *detailLabel, *separatorLine;
	UITextField	*input;
	UIImageView	*type;
}

@property (nonatomic, assign) IBOutlet UILabel *label, *detailLabel, *separatorLine;
@property (nonatomic, assign) IBOutlet UITextField *input;
@property (nonatomic, assign) IBOutlet UIImageView *type;

@end
