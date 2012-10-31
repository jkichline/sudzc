//
//  SoapParameter.h
//  Giant
//
//  Created by Jason Kichline on 7/13/09.
//  Copyright 2009 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SoapParameter : NSObject

@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) id value;

- (id)initWithValue:(id)value forName:(NSString *)name;
- (NSString *)xml;

@end
