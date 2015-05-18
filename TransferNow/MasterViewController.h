//
//  MasterViewController.h
//  FTAndMail
//
//  Created by Maria Grynychyn on 12/10/14.
//  Copyright (c) 2014 Maria Grynychyn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileServer.h"


@interface MasterViewController : UITableViewController

@property FileServer *network;
//- (void)configureStartCell;
-(void)didRemoveService;
- (void)send:(uint8_t)message;
@end

