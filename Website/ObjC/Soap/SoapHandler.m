/*
	SoapDelegate.m
	Implementation of a blank SOAP handler.
	Author:	Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
*/

#import "SoapHandler.h"

@implementation SoapHandler

- (void) onerror: (NSError*) error
{
}

- (void) onfault: (SoapFault*) fault
{
}

- (void) onload: (NSObject*) value
{
}

@end
