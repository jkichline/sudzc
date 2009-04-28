/*
 SoapObject.h
 Interface for the SoapObject base object that provides initialization and deallocation methods.
 Authors: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
          Karl Schulenburg, UMAI Development - Shoreditch, London UK
*/

#import "TouchXML.h"

@interface SoapObject : NSObject {
}

+ (id) newWithNode: (CXMLNode*) node;
- (id) initWithNode: (CXMLNode*) node;
- (NSString*) serialize;

@end