//
//  SoapObject.h
//
//  Interface for the SoapObject base object that provides initialization and
//  deallocation methods.
//
//  Authors: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
//           Karl Schulenburg, UMAI Development - Shoreditch, London UK
//

#import <Foundation/Foundation.h>
#import "TouchXML.h"
@class CXMLNode;

@interface SoapObject : NSObject

@property (nonatomic, copy) NSMutableArray *nanObjects;

+ (id)createWithNode:(CXMLNode *)node;
- (id)initWithNode:(CXMLNode *)node;
- (id)object;

- (NSMutableString *)serialize;
- (NSMutableString *)serialize:(NSString *)nodeName;
- (NSMutableString *)serializeElements;
- (NSMutableString *)serializeAttributes;

- (BOOL)isNaNProperty:(NSString *)propertyName;

@end
