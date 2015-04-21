//
//  Conversion.m
//  TransferNow
//
//  Created by Maria Grynychyn on 2/28/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import "Conversion.h"

static NSString *b=@"bytes";
static NSString *k=@"KB";
static NSString *m=@"MB";

@implementation Conversion

+ (NSString *) numberToString:(long)number{
    NSString *subtitle;
    if(number<1000){
        subtitle=[NSString stringWithFormat:@"%ld %@",number,b];
        return subtitle;
    }
    if(number >=1000 && number <1000000)
    {
        long  kb=number/1000;
        if(number%1000 <500)
            subtitle=[NSString stringWithFormat:@"%ld %@",kb,k];
        else
            subtitle=[NSString stringWithFormat:@"%ld %@",kb+1,k];
        return subtitle;
        
    }
    
    long  mb=number/1000000;
    long  decimal=number%1000000/100000;
    if(decimal==0)
        subtitle=[NSString stringWithFormat:@"%ld %@",mb,m];
    else
        subtitle=[NSString stringWithFormat:@"%ld.%ld %@",mb,decimal,m];
    
    return subtitle;
}

@end
