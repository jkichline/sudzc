//
//  SoapHandler.h
//
//  Implementation of a blank SOAP handler.
//  Author: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
//

#import "SoapFault.h"
#import "SoapDelegate.h"

@interface SoapHandler : NSObject <SoapDelegate>

- (void)onload:(id)value;
- (void)onerror:(NSError *)error;
- (void)onfault:(SoapFault *)fault;

@end
