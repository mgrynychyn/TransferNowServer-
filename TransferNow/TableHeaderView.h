//
//  TableHeaderView.h
//  TransferNow
//
//  Created by Maria Grynychyn on 4/9/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol  TableHeaderViewDelegate;

@interface TableHeaderView : UIView
@property (nonatomic, weak, readwrite) id<TableHeaderViewDelegate>    delegate;
@end

@protocol TableHeaderViewDelegate

-(void) startBrowser;
-(void) stopBrowser;
@end