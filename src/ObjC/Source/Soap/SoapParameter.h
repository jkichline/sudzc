//
//  SoapParameter.h
//  Giant
//
//  Created by Jason Kichline on 7/13/09.
//  Copyright 2009 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SoapParameter : NSObject {
	NSString* name;
	NSString* xml;
	id value;
	BOOL null;
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) id value;
@property (readonly) BOOL null;
@property (nonatomic, retain, readonly) NSString* xml;

-(id)initWithValue:(id)value forName: (NSString*) name;

@end
