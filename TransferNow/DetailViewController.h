//
//  DetailViewController.h
//  TransferNow
//
//  Created by Maria Grynychyn on 2/27/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

