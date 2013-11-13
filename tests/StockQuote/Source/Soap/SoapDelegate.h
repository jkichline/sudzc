//
//  SoapDelegate.h
//
//  Interfaces for the SoapDelegate protocol.
//  Authors: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
//

#import "SoapFault.h"

@protocol SoapDelegate <NSObject>

@required
- (void)onload:(id)value;

@optional
- (void)onerror:(NSError *)error;
- (void)onfault:(SoapFault *)fault;

@end