//
//  SoapObject.m
//
//  Implementation for the SoapObject base object that provides initialization and
//  deallocation methods.
//
//  Authors: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
//           Karl Schulenburg, UMAI Development - Shoreditch, London UK
//

#import "SoapObject.h"

#import "Soap.h"
#import <objc/runtime.h>

@implementation SoapObject

// Initialization include for every object - important (NSString and NSDates's to nil) - Karl
- (id)init
{
    self = [super init];
    if (self) {
        _nanObjects = [NSMutableArray array];
    }
    return self;
}

// Static method for initializing from a node.
+ (id)createWithNode:(CXMLNode *)node
{
    return [[SoapObject alloc] initWithNode:node];
}

// Called when initializing the object from a node
- (id)initWithNode:(CXMLNode *)node
{
    self = [self init];
    if (self) {
        unsigned int outCount;
        objc_property_t *properties = class_copyPropertyList([self class], &outCount);
        for (int i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            NSString *tempName = @(property_getName(property));
            char typeChar = ' ';
            if (strlen(property_getAttributes(property)) > 2) {
                typeChar = property_getAttributes(property)[1]; // get type character
            }
            if ([[Soap getNodeValue:node withName:tempName] isEqualToString:@"NaN"] &&
                (typeChar != '@' && typeChar != '*' && typeChar != '#' && typeChar != ':')) {
                [self.nanObjects addObject:tempName];
            }
        }
        free(properties);
    }

    return self;
}

// This will get called when traversing objects, returning nothing is ok - Karl
- (NSMutableString *)serialize
{
    return [NSMutableString string];
}

- (NSMutableString *)serialize:(NSString *)nodeName
{
    return [NSMutableString string];
}

- (NSMutableString *)serializeElements
{
    return [NSMutableString string];
}

- (NSMutableString *)serializeAttributes
{
    return [NSMutableString string];
}

- (id)object
{
    return self;
}

- (NSString *)description
{
    return [Soap serialize:self];
}

- (BOOL)isNaNProperty:(NSString *)propertyName
{
    return ([self.nanObjects containsObject:propertyName]);
}


@end
