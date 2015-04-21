//
//  MyFile.h
//  FTAndMail
//
//  Created by Maria Grynychyn on 1/18/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyFile : NSObject

@property NSString *name;
@property BOOL isDirectory;
@property BOOL isDownloaded;
@property BOOL isSelected;
@property long size;

- initWithName:(NSString *)name;
@end
