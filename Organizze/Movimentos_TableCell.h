//
//  Movimentos_TableCell.h
//  Organizze
//
//  Created by Cassio Rossi on 22/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

@interface Movimentos_TableCell : UITableViewCell {
	UILabel		*movimento, *valor, *categoria, *pago, *background;
	UIImageView	*tag;
}

@property (nonatomic, assign) IBOutlet UILabel		*movimento, *valor, *categoria, *pago, *background;
@property (nonatomic, assign) IBOutlet UIImageView	*tag;

@end
