//
//  MasterViewController.h
//  FTAndMail
//
//  Created by Maria Grynychyn on 12/10/14.
//  Copyright (c) 2014 Maria Grynychyn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGNetwork.h"

@interface MasterViewController : UITableViewController

@property MGNetwork *network;
//- (void)configureStartCell;
-(void)didRemoveService;
@end

