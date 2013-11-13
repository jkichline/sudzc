//
//  SoapLiteral.m
//
//  Created by Jason Kichline on 8/7/10.
//  Copyright 2010 andCulture. All rights reserved.
//

#import "SoapLiteral.h"

@implementation SoapLiteral

- (id)initWithString:(NSString *)string
{
    self = [super init];
    if (self) {
        _value = string;
    }
    return self;
}

+ (SoapLiteral *)literalWithString:(NSString *)string
{
    return [[SoapLiteral alloc] initWithString:string];
}

@end
