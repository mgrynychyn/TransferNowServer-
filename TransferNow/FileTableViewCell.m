//
//  FileTableViewCell.m
//  FTAndMail
//
//  Created by Maria Grynychyn on 2/23/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import "FileTableViewCell.h"

static NSIndexPath * selectedIndexPath;
static NSIndexPath * downloadIndexPath;

static UIButton * downloadButton;
//static UIProgressView * downloadProgress;
@implementation FileTableViewCell

+ (NSIndexPath *)selectedIndexPath{
    return selectedIndexPath;
}

+ (void)setSelectedIndexPath:(NSIndexPath *)indexPath{
    selectedIndexPath=indexPath;
}

+ (NSIndexPath *)downloadIndexPath{
    return downloadIndexPath;
}

+ (void)setDownloadIndexPath:(NSIndexPath *)indexPath{
    downloadIndexPath=indexPath;
}


+ (void) setDownloadButton{
    
    CGRect frame=CGRectZero;
    
    UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem] ;
    [button setFrame:frame];
    button.backgroundColor=[UIColor colorWithRed:18 green:0 blue:148 alpha:255];
    
    [button setTitle:@"Download" forState:UIControlStateNormal];
    button.tag=BUTTON_TAG;
    button.clipsToBounds=YES;
    
    button.exclusiveTouch=YES;
    
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    downloadButton=button;
    
   
}

+ (UIButton *) downloadButton{
    
    return downloadButton;
}

- (void)awakeFromNib {

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews
{
    
    [super layoutSubviews];
    
    CGPoint point=CGPointMake(self.contentView.frame.size.width/2-43.5, self.contentView.frame.size.height/2);
    CGPoint position=CGPointMake(self.bounds.size.width-81.5/2.0, self.bounds.size.height/2.0);
    CGRect bounds = CGRectMake(0.0, 0.0, 81.5, self.bounds.size.height);
    if(((selectedIndexPath!=nil) && [selectedIndexPath isEqual:self.indexPath])
       ){
        
        self.contentView.layer.position=point;
        
        downloadButton.layer.position=position;
        downloadButton.layer.bounds=bounds;
        
    }
    
    
}

- (void) animate{
    
    // Change the position explicitly.
    CABasicAnimation* theAnim = [CABasicAnimation animationWithKeyPath:@"position"];
    theAnim.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.contentView.frame.size.width/2, self.contentView.frame.size.height/2)];
    theAnim.toValue = [NSValue valueWithCGPoint:CGPointMake(self.contentView.frame.size.width/2-43.5, self.contentView.frame.size.height/2)];
    //    theAnim.toValue = [NSValue valueWithCGPoint:CGPointMake(cell.contentView.layer.position.x-81.5,cell.contentView.layer.position.y)];
    theAnim.duration = 0.5;
    theAnim.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.contentView.layer addAnimation:theAnim forKey:@"position"];
    
    //   [cell layoutIfNeeded];
    
    CGPoint positionFrom=CGPointMake(self.bounds.size.width, self.bounds.size.height/2.0);
    CGPoint positionTo=CGPointMake(self.bounds.size.width-81.5/2.0, self.bounds.size.height/2.0);
    
    CABasicAnimation* theAnim2 = [CABasicAnimation animationWithKeyPath:@"position"];
    theAnim2.fromValue = [NSValue valueWithCGPoint:positionFrom];
    theAnim2.toValue = [NSValue valueWithCGPoint:positionTo];
    
    theAnim2.duration = 0.5;
    theAnim2.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [downloadButton.layer addAnimation:theAnim2 forKey:@"buttonPosition"];
    
    CABasicAnimation* theAnim3 = [CABasicAnimation animationWithKeyPath:@"bounds"];
    theAnim3.fromValue = [NSValue valueWithCGRect:CGRectMake(0.0, 0.0, 0.1, self.bounds.size.height)];
    //   theAnim3.fromValue = [NSValue valueWithCGRect:CGRectZero];
    theAnim3.toValue = [NSValue valueWithCGRect:CGRectMake(0.0, 0.0, 81.5, self.bounds.size.height)];
    theAnim.duration = 0.5;
    theAnim.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [downloadButton.layer addAnimation:theAnim3 forKey:@"bounds"];
    
    [self layoutIfNeeded];
    
}

- (void) animateBack{
    
    
    CABasicAnimation* theAnim = [CABasicAnimation animationWithKeyPath:@"position"];
    theAnim.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.contentView.frame.size.width/2-43.5, self.contentView.frame.size.height/2)];
    theAnim.toValue = [NSValue valueWithCGPoint:CGPointMake(self.contentView.frame.size.width/2, self.contentView.frame.size.height/2)];
    
    
    theAnim.duration = 0.5;
    theAnim.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.contentView.layer addAnimation:theAnim forKey:@"position"];
    
    CGPoint positionFrom=CGPointMake(self.bounds.size.width-81.5/2.0, self.bounds.size.height/2.0);
    CGPoint positionTo=CGPointMake(self.bounds.size.width-1, self.bounds.size.height/2.0);
    
    CABasicAnimation* theAnim2 = [CABasicAnimation animationWithKeyPath:@"position"];
    theAnim2.fromValue = [NSValue valueWithCGPoint:positionFrom];
    theAnim2.toValue = [NSValue valueWithCGPoint:positionTo];
    
    theAnim2.duration = 0.5;
    theAnim2.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [downloadButton.layer addAnimation:theAnim2 forKey:@"buttonPosition"];
    
    CABasicAnimation* theAnim3 = [CABasicAnimation animationWithKeyPath:@"bounds"];
    theAnim3.fromValue = [NSValue valueWithCGRect:CGRectMake(0.0, 0.0, 81.5, self.bounds.size.height)];
    //   theAnim3.fromValue = [NSValue valueWithCGRect:CGRectZero];
    theAnim3.toValue = [NSValue valueWithCGRect:CGRectMake(0.0, 0.0, 0.1, self.bounds.size.height)];
    theAnim3.duration = 0.5;
    theAnim.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [downloadButton.layer addAnimation:theAnim3 forKey:@"bounds"];
    
}

@end
