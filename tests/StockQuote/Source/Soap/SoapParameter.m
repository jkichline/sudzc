//
//  SoapParameter.m
//  Giant
//
//  Created by Jason Kichline on 7/13/09.
//  Copyright 2009 andCulture. All rights reserved.
//

#import "SoapParameter.h"
#import "Soap.h"

@implementation SoapParameter

- (id)initWithValue:(id)valueParam forName:(NSString *)nameValue
{
    self = [super init];
    if (self) {
        _name = nameValue;
        _value = valueParam;
    }
    return self;
}

- (NSString *)xml
{
    if (self.value == nil) {
        return [NSString stringWithFormat:@"<%@ xsi:nil=\"true\"/>", self.name];
    }

    return [Soap serialize:self.value withName:self.name];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", self.name, self.value];
}

@end
