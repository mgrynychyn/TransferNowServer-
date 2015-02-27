//
//  MyFile.m
//  FTAndMail
//
//  Created by Maria Grynychyn on 1/18/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import "MyFile.h"

@interface MyFile()
    
@end
@implementation MyFile

- initWithName:(NSString *)name{
    self=[super init];
    if(self){
        _name=name;
        _isDownloaded=NO;
        return self;
    }
    
    return nil;

}

@end
