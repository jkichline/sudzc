/*
 SoapFault.m
 Implementation that constructs a fault object from a SOAP fault when the
 web service returns an error.
 
 Author:	Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
*/

#import "SoapFault.h"
#import "Soap.h"

@implementation SoapFault

@synthesize faultCode, faultString, faultActor, detail, hasFault;

+ (SoapFault*) faultWithData: (NSMutableData*) data {
	NSError* error;
	CXMLDocument* doc = [[CXMLDocument alloc] initWithData: data options: 0 error: &error];
	if(doc == nil) { return [[SoapFault alloc] init]; }
	return [SoapFault faultWithXMLDocument: doc];
}

+ (SoapFault*) faultWithXMLDocument: (CXMLDocument*) document {
	return [SoapFault faultWithXMLElement: [Soap findNode: document xpath: @"//*/fault"]];
}

+ (SoapFault*) faultWithXMLElement: (CXMLNode*) element {
	SoapFault* this = [[SoapFault alloc] init];
	this.hasFault = NO;
	if(element == nil) {
		return this;
	}
	this.faultCode = [Soap getNodeValue: element withName: @"faultcode"];
	this.faultString = [Soap getNodeValue: element withName: @"faultstring"];
	this.faultActor = [Soap getNodeValue: element withName: @"faultactor"];
	this.detail = [Soap getNodeValue: element withName: @"detail"];
	this.hasFault = YES;
	return this;
}

@end
