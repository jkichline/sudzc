//
//  NSMutableArray+Soap.h
//  SudzCExamples
//
//  Created by Jason Kichline on 12/14/10.
//  Copyright 2010 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TouchXML.h"

@interface NSMutableArray (Soap)

+(NSMutableArray*)createWithNode: (CXMLNode*) node;
-(id)initWithNode:(CXMLNode*)node;
+(NSMutableString*) serialize: (NSArray*) array;
-(id)object;

@end
