//
//  FileTableViewCell.m
//  FTAndMail
//
//  Created by Maria Grynychyn on 2/23/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import "FileTableViewCell.h"

@interface FileTableViewCell()
@property (strong, nonatomic) UILabel *downloadLabel;
@end

@implementation FileTableViewCell

- (void)awakeFromNib {
    
    UIImage *downloadImage=[UIImage imageNamed:@"CellImage3.png"];
    self.accessoryView=[[UIImageView alloc] initWithImage:downloadImage];
//    self.editingAccessoryView=self.downloadLabel;
//    self.detailTextLabel.text=@"File downloaded";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureDownloadLabel{
    
    CGRect frame = CGRectMake(270, 0.0, self.frame.size.width, self.frame.size.height);
    
    UILabel *label=[[UILabel alloc] initWithFrame:frame];
    label.text=@"Download";
    
    label.backgroundColor=[UIColor blueColor];
    label.textColor=[UIColor whiteColor];
    label.adjustsFontSizeToFitWidth=YES;
    self.downloadLabel=label;
}
@end
