/*
 SoapFault.h
 Interface that constructs a fault object from a SOAP fault when the
 web service returns an error.

 Author:	Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
*/

#import "TouchXML.h"

@interface SoapFault : NSObject {
	NSString* faultCode;
	NSString* faultString;
	NSString* faultActor;
	NSString* detail;
	BOOL hasFault;
}

@property (retain, nonatomic) NSString* faultCode;
@property (retain, nonatomic) NSString* faultString;
@property (retain, nonatomic) NSString* faultActor;
@property (retain, nonatomic) NSString* detail;
@property BOOL hasFault;

+ (SoapFault*) faultWithData: (NSMutableData*) data;
+ (SoapFault*) faultWithXMLDocument: (CXMLDocument*) document;
+ (SoapFault*) faultWithXMLElement: (CXMLNode*) element;

@end
