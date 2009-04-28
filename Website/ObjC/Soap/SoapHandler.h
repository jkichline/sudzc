/*
 SoapDelegate.h
 Interfaces for the SoapDelegate protocol and the concrete SoapHandler class.
 Author:	Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
*/

#import "SoapFault.h"

@protocol SoapDelegate <NSObject>

- (void) onload: (NSObject*) value;

@optional
- (void) onerror: (NSError*) error;
- (void) onfault: (SoapFault*) fault;

@end

@interface SoapHandler : NSObject <SoapDelegate>
{
}

- (void) onload: (NSObject*) value;
- (void) onerror: (NSError*) error;
- (void) onfault: (SoapFault*) fault;

@end