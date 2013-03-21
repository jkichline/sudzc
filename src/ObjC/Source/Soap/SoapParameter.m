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

@synthesize name, value, null, xml;

-(void)setValue:(id)valueParam{
	[valueParam retain];
	[value release];
	value = valueParam;
	null = (value == nil);
}

-(id)initWithValue:(id)valueParam forName: (NSString*) nameValue {
	if(self = [super init]) {
		self.name = nameValue;
		self.value = valueParam;
	}
	return self;
}

-(NSString*)xml{
	if(self.value == nil) {
		return [NSString stringWithFormat:@"<%@ xsi:nil=\"true\"/>", name];
	} else {
		return [Soap serialize: self.value withName: name];
	}
}

-(void)dealloc{
	[name release];
	[value release];
	[xml release];
	[super dealloc];
}

@end
