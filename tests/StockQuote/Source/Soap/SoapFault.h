//
//  SoapFault.h
//
//  Interface that constructs a fault object from a SOAP fault when the
//  web service returns an error.
//  Authors: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
//

#import "TouchXML.h"

@interface SoapFault : NSObject

@property (nonatomic, strong) NSString *faultCode;
@property (nonatomic, strong) NSString *faultString;
@property (nonatomic, strong) NSString *faultActor;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, assign) BOOL hasFault;

+ (SoapFault *)faultWithData:(NSMutableData *)data;
+ (SoapFault *)faultWithXMLDocument:(CXMLDocument *)document;
+ (SoapFault *)faultWithXMLElement:(CXMLNode *)element;

@end
