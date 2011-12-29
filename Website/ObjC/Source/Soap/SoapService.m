#import "SoapService.h"

@implementation SoapService

@synthesize serviceUrl = _serviceUrl;
@synthesize namespace = _namespace;
@synthesize logging = _logging;
@synthesize headers = _headers;
@synthesize defaultHandler = _defaultHandler;
@synthesize username = _username;
@synthesize password = _password;

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

- (id) initWithUsername: (NSString*) username andPassword: (NSString*) password {
	if(self = [self init]) {
		self.username = username;
		self.password = password;
	}
	return self;
}

-(void)dealloc {
	[_serviceUrl release];
	[_namespace release];
	[_username release];
	[_password release];
	[_headers release];
	[_defaultHandler release];
	[super dealloc];
}

@end