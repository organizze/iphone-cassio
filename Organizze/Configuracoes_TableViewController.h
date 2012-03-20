//
//  Configuracoes_TableViewController.h
//  Organizze
//
//  Created by Cassio Rossi on 11/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "parser.h"

#define WHATTODO_SYNC	0
#define WHATTODO_MAIS	1

@interface Configuracoes_TableViewController : UITableViewController <parserDelegate> {
	NSMutableArray		*configOptions;
	int					 whatToDo;
}

@property (nonatomic, retain) NSMutableArray *configOptions;

- (void)back;
- (void)blockApp:(id)sender;

@end
