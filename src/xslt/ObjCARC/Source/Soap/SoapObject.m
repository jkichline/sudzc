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

- (NSNumber *)numberForPrimitiveSelector:(SEL)selector
{
    if ([self isNaNProperty:NSStringFromSelector(selector)]) {
        return nil;
    }

    if (![self respondsToSelector:selector]) {
        DDLogWarn(@"The provided object %@ does not respond to %@", self, NSStringFromSelector(selector));
        return nil;
    }

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[self class] instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:self];
    [invocation invoke];

  const char *methodReturnType = [[invocation methodSignature] methodReturnType];
  switch (*methodReturnType)
  {
    case 'c':
    {
      int8_t value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithChar:value];
    }
    case 'C':
    {
      uint8_t value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithUnsignedChar:value];
    }
    case 'i':
    {
      int32_t value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithInt:value];
    }
    case 'I':
    {
      uint32_t value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithUnsignedInt:value];
    }
    case 's':
    {
      int16_t value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithShort:value];
    }
    case 'S':
    {
      uint16_t value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithUnsignedShort:value];
    }
    case 'f':
    {
      float value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithFloat:value];
    }
    case 'd':
    {
      double value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithDouble:value];
    }
    case 'B':
    {
      uint8_t value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithBool:(BOOL)value];
    }
    case 'l':
    {
      long value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithLong:value];
    }
    case 'L':
    {
      unsigned long value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithUnsignedLong:value];
    }
    case 'q':
    {
      long long value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithLongLong:value];
    }
    case 'Q':
    {
      unsigned long long value;
      [invocation getReturnValue:&value];
      return [NSNumber numberWithUnsignedLongLong:value];
    }
            //    case '*':
            //    {
            //
            //    }
    case '@':
    {
      id value;
      [invocation getReturnValue:&value];
      return value;
    }
    case 'v':
    {
      return nil;
    }
    default:
    {
      [NSException raise:NSInternalInconsistencyException format:@"[%@ %@] UnImplemented type: %s",
             [self class], NSStringFromSelector(_cmd), methodReturnType];
    }
  }

    return nil;
}

@end
