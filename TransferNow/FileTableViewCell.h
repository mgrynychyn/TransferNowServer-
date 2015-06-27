//
//  FileTableViewCell.h
//  FTAndMail
//
//  Created by Maria Grynychyn on 2/23/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import <UIKit/UIKit.h>
#define BUTTON_TAG 11

@interface FileTableViewCell : UITableViewCell

+ (NSIndexPath *) selectedIndexPath;
+ (void) setSelectedIndexPath :(NSIndexPath *)indexPath;

+ (NSIndexPath *) downloadIndexPath;
+ (void) setDownloadIndexPath :(NSIndexPath *)indexPath;

//+ (void) initializePositions:(MyTableViewCell *)cell;
+ (UIButton *) downloadButton;
//+ (UIProgressView *) downloadProgress;
+ (void) setDownloadButton;

@property NSIndexPath *indexPath;

-(void)animate;
-(void)animateBack;
@end
