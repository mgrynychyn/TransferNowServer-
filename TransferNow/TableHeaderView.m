//
//  TableHeaderView.m
//  TransferNow
//
//  Created by Maria Grynychyn on 4/9/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import "TableHeaderView.h"

static NSString * serviceLabel =@"Start TransferNowM on your computer and turn WIFI or Bluetooth® on";
static NSString * startButton = @"Start  browsing";
static NSString * stopButton = @"Stop browsing";
static NSString * initial = @"Disconnected";

@interface TableHeaderView()

@property UILabel *monitorLabel;
@property UIButton *button;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@end

@implementation TableHeaderView

- (id) initWithFrame:(CGRect)frame{
   
    self=[super initWithFrame:frame];
    
    if(self!=nil){
        
        CGRect anotherFrame=CGRectMake(self.bounds.size.width*0.17, 0.0, self.bounds.size.width*0.75,  self.bounds.size.height*0.3);
  //       CGRect anotherFrame=CGRectMake(self.bounds.size.width/8, 0.0, self.bounds.size.width*0.75,  self.bounds.size.height*0.25);
        _monitorLabel = [[UILabel alloc] initWithFrame:anotherFrame];
        _monitorLabel.text=serviceLabel;
        _monitorLabel.numberOfLines=3;
        _monitorLabel.adjustsFontSizeToFitWidth=YES;
      _monitorLabel.font=[UIFont systemFontOfSize: 23];
   //     _monitorLabel.font=[UIFont systemFontOfSize: 20];
        _monitorLabel.baselineAdjustment=UIBaselineAdjustmentNone;
        
        anotherFrame = CGRectMake(self.bounds.size.width/8, self.bounds.size.height*0.35, self.bounds.size.width*0.75,  self.bounds.size.height*0.1125);
        
        _button=[UIButton buttonWithType:UIButtonTypeSystem] ;
        [_button setFrame:anotherFrame];
        _button.backgroundColor=[UIColor darkGrayColor];
        _button.layer.cornerRadius=10.0;
        [_button setTitle:startButton forState:UIControlStateNormal];
        _button.titleLabel.font = [UIFont systemFontOfSize: 24];
        [_button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_button addTarget:self
                    action:@selector(buttonSelected:)
          forControlEvents:UIControlEventTouchDown];
        
        [self addSubview:_monitorLabel];
        
        [self addSubview:_button];
    }
    
    return self;
}

-(void) buttonSelected:(UIButton *)sender{
    
    if([sender.titleLabel.text isEqual:stopButton]){
        
        [sender setTitle:startButton forState:UIControlStateNormal];
 //       [self.network stopBrowser];
        if(_activityIndicator!=nil){
            [_activityIndicator removeFromSuperview];
            _activityIndicator=nil;
        }
        [self.delegate stopBrowser];
    }
    
    else{
        
        [sender setTitle:stopButton forState:UIControlStateNormal];
        
        [self addBrowsingIndicator];
 //       if(self.network!=nil)
 //           [self.network startBrowser];
        [self.delegate startBrowser];
    }
}

- (void) addBrowsingIndicator{
    
    _activityIndicator=[[UIActivityIndicatorView alloc] init];
    _activityIndicator.activityIndicatorViewStyle= UIActivityIndicatorViewStyleWhite;
    CGPoint point=_button.center;
    point.y-=_button.bounds.size.height*1.25;
    _activityIndicator.center= point;
    
    [self addSubview:_activityIndicator];
    
    [_activityIndicator startAnimating];
}

@end
