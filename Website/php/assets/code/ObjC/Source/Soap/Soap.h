/*
 Soap.h
 Provides method for serializing and deserializing values to and from the web service.
 Authors:	Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
          Karl Schulenburg, UMAI Development - Shoreditch, London UK
*/

#import "TouchXML.h"
#import "SoapArray.h"
#import "SoapDelegate.h"
#import "SoapDictionary.h"
#import "SoapFault.h"
#import "SoapHandler.h"
#import "SoapLiteral.h"
#import "SoapNil.h"
#import "SoapObject.h"
#import "SoapParameter.h"
#import "SoapRequest.h"
#import "SoapService.h"
#import "SoapReachability.h"
#import "NSMutableArray+Soap.h"

@interface Soap : NSObject {
	
}

// Creates the XML request for the SOAP envelope.
+ (NSString*) createEnvelope: (NSString*) method forNamespace: (NSString*) ns forParameters: (NSString*) params;

// Creates the XML request for the SOAP envelope with optional SOAP headers.
+ (NSString*) createEnvelope: (NSString*) method forNamespace: (NSString*) ns forParameters: (NSString*) params withHeaders: (NSDictionary*) headers;

// Creates the XML request for the SOAP envelope.
+ (NSString*) createEnvelope: (NSString*) method forNamespace: (NSString*) ns containing: (NSDictionary*) containing;

// Creates the XML request for the SOAP envelope with optional SOAP headers.
+ (NSString*) createEnvelope: (NSString*) method forNamespace: (NSString*) ns containing: (NSDictionary*) containing withHeaders: (NSDictionary*) headers;

// Creates the XML request for the SOAP envelope.
+ (NSString*) createEnvelope: (NSString*) method forNamespace: (NSString*) ns withParameters: (NSArray*) params;

// Creates the XML request for the SOAP envelope with optional SOAP headers.
+ (NSString*) createEnvelope: (NSString*) method forNamespace: (NSString*) ns withParameters: (NSArray*) params withHeaders: (NSDictionary*) headers;

// Creates the XML request for the SOAP envelope. - Karl
+ (NSString*) createEnvelope: (NSString*) method ofAction: (NSString*) action forNamespace: (NSString*) ns containing: (SoapObject*) containing;

// Creates the XML request for the SOAP envelope with optional SOAP headers.
+ (NSString*) createEnvelope: (NSString*) method ofAction: (NSString*) action forNamespace: (NSString*) ns containing: (SoapObject*) containing withHeaders: (NSDictionary*) headers;

// Serializes an object to a string, XML representation.
+ (NSString*) serialize: (id) object;

// Serializes an object to a string, XML representation with a specific node name.
+ (NSString*) serialize: (id) object withName: (NSString*) nodeName;

// Serializes a header in the dictionary
+(NSString*)serializeHeader:(NSDictionary*)headers forKey:(NSString*)key;

// Calls an HTTP service
+ (NSMutableData*) callService: (NSString*) service data: (NSString*) data action: (NSString*) action delegate: (SEL) delegate;

// Gets the node from another node by name
+ (CXMLNode*) getNode: (CXMLNode*) element withName: (NSString*) name;

// Finds nodes in a parent with a given XPath query
+ (NSArray*) findNodes: (CXMLNode*) node xpath: (NSString*) xpath;

// Finds a single node with the given XPath query
+ (CXMLNode*) findNode: (CXMLNode*) node xpath: (NSString*) xpath;

// Deserializes an element to a string value.
+ (id) deserialize: (CXMLNode*) element;

// Deserializes a node into an object.
+ (id) deserialize: (CXMLNode*) element forObject: (NSObject*) object;

// Deserializes the element in a dictionary.
+ (id) deserializeAsDictionary:(CXMLNode*)element ;

// Determines if an object is an array
+ (BOOL) isArray: (NSObject*) value;

// Determines if an object is an object with properties.
+ (BOOL) isObject: (NSObject*) value;

// Gets the value of a named node from a parent node.
+ (NSString*) getNodeValue: (CXMLNode*) node withName: (NSString*) name;

// Converts a string to a specific type.
+ (id) convert: (NSString*) value toType: (NSString*) toType;

// Converts a string to a date.
+ (NSDate*) dateFromString: (NSString*) value;

// Converts a date to a string.
+ (NSString*) getDateString: (NSDate*) value;

// Converts a string to a duration.
+ (NSTimeInterval) durationFromString: (NSString*) value;

// Converts a duration to a string.
+ (NSString*) getDurationString: (NSTimeInterval) value;

// Return NSData from a string.
+(NSData*) dataFromString:(NSString*) value;

// Returns a string version of binary data.
+(NSString*)getBase64String:(NSData*) value;

// Generates an MD5 hash
+(NSString*)md5:(NSString*)value;

// Creates a unique hash for the object's contents.
+(NSUInteger)generateHash:(SoapObject*)value;

// Creates and object of string values from the node.
+(id)objectFromNode:(CXMLNode*)node;

// Creates dictionary of string values from the XML document.
+(id)objectFromXMLString:(NSString*)xmlString;

@end
