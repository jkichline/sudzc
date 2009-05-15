/*
 Soap.m
 Provides method for serializing and deserializing values to and from the web service.

 Authors: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
          Karl Schulenburg, UMAI Development - Shoreditch, London UK
*/

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "Soap.h"

@implementation Soap

// Creates the XML request for the SOAP envelope.
+ (NSString*) createEnvelope: (NSString*) method forNamespace: (NSString*) ns forParameters: (NSString*) params
{
	NSMutableString* s = [[NSMutableString alloc] init];
	[s appendString: @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
	[s appendFormat: @"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns=\"%@\">", ns];
	[s appendString: @"<soap:Body>"];
	[s appendFormat: @"<%@>%@</%@>", method, params, method];
	[s appendString: @"</soap:Body>"];
	[s appendString: @"</soap:Envelope>"];

	return s;
}

// Creates the XML request for the SOAP envelope.
+ (NSString*) createEnvelope: (NSString*) method forNamespace: (NSString*) ns containing: (NSDictionary*) containing
{
	NSMutableString* s = [[NSMutableString alloc] init];
	for(id key in containing) {
		[s appendFormat: @"<%@>%@</%@>", key, [Soap serialize:[containing objectForKey: key]], key];
	}
	return [Soap createEnvelope: method forNamespace: ns forParameters: s];
}

// Creates the XML request for the SOAP envelope. - Karl
+ (NSString*) createEnvelope: (NSString*) method ofAction: (NSString*) action forNamespace: (NSString*) ns containing: (SoapObject*) containing
{
	NSMutableString* s = [[NSMutableString alloc] init];
	[s appendFormat: @"<%@>%@</%@>", method, [containing serialize], method];
	return [Soap createEnvelope: action forNamespace: ns forParameters: s];
}

// Serializes an object to a string, XML representation.
+ (NSString*) serialize: (id) object {

	// If it's not an object, just return it as a string.
	if([Soap isObject: object] == NO) {
		return (NSString*)object;
	}
	
	// If it s an array, then serialize it as an array.
	if([Soap isArray: object]) {
		//# NOT IMPLEMENTED
	}

	// Otherwise we need to serialize the object as XML.
	unsigned int outCount, i;
	NSMutableString* s = [[NSMutableString alloc] init];
	NSMutableDictionary* keys = [[NSMutableDictionary alloc] init];

	Class currentClass = [object class];
	while(currentClass != nil) {
		objc_property_t *properties = class_copyPropertyList([object class], &outCount);
		if(outCount > 0) {
			for(i = 0; i < outCount; i++) {
				NSString *name = [NSString stringWithCString: property_getName(properties[i])];
				if([keys valueForKey: name] == nil) {
					[s appendFormat: @"<%@>%@</%@>", name, [Soap serialize: (id)properties[i]], name];
					[keys setValue: name forKey: name];
				}
			}
		}
	}
	[keys release];
	return (NSString*)s;}

// Calls an HTTP service.
+ (NSMutableData*) callService: (NSString*) urlString data: (NSString*) data action: (NSString*) action delegate: (SEL) handler {
	NSURL* url = [NSURL URLWithString: urlString];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: url];
	NSMutableData* output;

	if(action != nil) {
		[request addValue: action forHTTPHeaderField: @"SOAPAction"];
	}
	if(data != nil) {
		[request setHTTPMethod: @"POST"];
		[request setHTTPBody: [data dataUsingEncoding: NSUTF8StringEncoding]];
		[request addValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
	}

	NSURLConnection* conn = [[NSURLConnection alloc] initWithRequest: request delegate: self];
	if(conn) {
		output = [[NSMutableData data] retain];
	}
	[NSURLConnection connectionWithRequest: request delegate: self];
	
	NSError* error;
	NSURLResponse* response;

	return (NSMutableData*)[NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];
//	return output;
}

// Gets the node from another node by name.
+ (CXMLNode*) getNode: (CXMLNode*) element withName: (NSString*) name {
	for(CXMLNode* child in [element children]) {
		if([[child name] isEqual: name]) {
			return (CXMLNode*)child;
		}
	}
	for(CXMLNode* child in [element children]) {
		CXMLNode* el = [Soap getNode: (CXMLElement*)child withName: name];
		if(el != nil) { return el; }
	}
	return nil;
}

// Finds nodes in a parent with a given XPath query.
+ (NSArray*) findNodes: (CXMLNode*) node xpath: (NSString*) xpath {
	NSError* error;
	return [node nodesForXPath: xpath error: &error];
}

// Finds a single node with the given XPath query.
+ (CXMLNode*) findNode: (CXMLNode*) node xpath: (NSString*) xpath {
	NSArray* a = [Soap findNodes: node xpath: xpath];
	if(a != nil && [a count] > 0) {
		return (CXMLNode*)[a objectAtIndex:0];
	}
	return nil;
}

// Deserializes a node into an object.
+ (NSObject*) deserialize: (CXMLNode*) element forObject: (NSObject*) object {
	NSError* error;
	NSObject* value;
	NSArray* nodes = [element nodesForXPath:@"*" error: &error];
	for(CXMLNode* node in nodes) {
		NSObject* property = [object valueForKey: [node name]];
		Class cls = NSClassFromString([node name]);
		id object = [[cls alloc] init];
		if([Soap isArray: property]) {
			// Fill as if an array
		} else {
			if([Soap isObject: property]) {
				// Instantiate the object type from the node name and deserialize
			} else {
				// Figure out the value type and return it I think
			}
		}

		[object setValue: [node stringValue] forKey: [node name]];
	}
	return value;
}

// Determines if an object is an array.
+ (BOOL) isArray: (NSObject*) value {
	return ([value class] == [NSArray class]);
}

// Determines if an object is an object with properties.
+ (BOOL) isObject: (NSObject*) value {
	return ([value class] == [SoapObject class]);
}

// Gets the value of a named node from a parent node.
+ (NSString*) getNodeValue: (CXMLNode*) node withName: (NSString*) name {

	// Set up the variables
	if(node == nil || name == nil) { return nil; }
	CXMLNode* child = nil;
	
	// If it's an attribute get it
	if([node class] == [CXMLElement class])
	{
		child = [(CXMLElement*)node attributeForName: name];
		if(child != nil) {
			return [child stringValue];
		}
	}

	// Otherwise get the first element
	child = [Soap getNode: node withName: name];
	if(child != nil) {
		return [child stringValue];
	}
	return nil;
}

+ (id) convert: (NSString*) value toType: (NSString*) toType {
	toType = [toType lowercaseString];
	if([toType isEqualToString: @"nsstring*"]) {
		return value;
	}
	if([toType isEqualToString: @"bool"]) {
		return [NSNumber numberWithBool:(([[value lowercaseString] isEqualToString: @"true"]) ? YES : NO)];
	}
	if([toType isEqualToString: @"int"]) {
		return [NSNumber numberWithInt:[value intValue]];
	}
	if([toType isEqualToString: @"long"]) {
		return [NSNumber numberWithLong:[value longLongValue]];
	}
	if([toType isEqualToString: @"double"]) {
		return [NSNumber numberWithDouble:[value doubleValue]];
	}
	if([toType isEqualToString: @"float"]) {
		return [NSNumber numberWithFloat:[value floatValue]];
	}
	if([toType isEqualToString: @"nsdecimalnumber*"]) {
		return [NSDecimalNumber decimalNumberWithString: value];
	}
	if([toType isEqualToString: @"nsdate*"]) {
		return [Soap getDate: value];
	}
	return value;
}

// Converts a string to a date.
+ (NSDate*) dateFromString: (NSString*) value {
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	NSLocale* enUS = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[formatter setLocale: enUS];
	[enUS release];
	[formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
	NSDate* outputDate = [formatter dateFromString: value];
	return outputDate;
}

@end
