//
//  SoapLiteral.h
//
//  Created by Jason Kichline on 8/7/10.
//  Copyright 2010 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SoapLiteral : NSObject

@property(nonatomic, strong) NSString *value;

- (id)initWithString:(NSString *)string;
+ (SoapLiteral *)literalWithString:(NSString *)string;

@end
