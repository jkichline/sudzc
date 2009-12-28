#import "SoapService.h"

@implementation SoapService

@synthesize serviceUrl, namespace, logging, headers, defaultHandler, username, password;

- (id) init {
	if(self = [super init]) {
		self.serviceUrl = nil;
		self.namespace = nil;
		self.logging = NO;
		self.headers = nil;
		self.defaultHandler = nil;
		self.username = nil;
		self.password = nil;
	}
	return self;
}

- (id) initWithUrl: (NSString*) url {
	if(self = [self init]) {
		self.serviceUrl = url;
	}
	return self;
}
	
@end