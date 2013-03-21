/*
 SoapObject.h
 Interface for the SoapObject base object that provides initialization and deallocation methods.
 Authors: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
          Karl Schulenburg, UMAI Development - Shoreditch, London UK
*/

#import "TouchXML.h"

@interface SoapObject : NSObject {
}

@property (readonly) id object;

+ (id) createWithNode: (CXMLNode*) node;
- (id) initWithNode: (CXMLNode*) node;
- (NSMutableString*) serialize;
- (NSMutableString*) serialize: (NSString*) nodeName;
- (NSMutableString*) serializeElements;
- (NSMutableString*) serializeAttributes;

@end