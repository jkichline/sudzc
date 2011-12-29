#import "SoapDelegate.h"

@interface SoapService : NSObject
{
	NSString* _serviceUrl;
	NSString* _namespace;
	NSString* _username;
	NSString* _password;
	NSDictionary* _headers;
	BOOL _logging;
	id<SoapDelegate> _defaultHandler;
}

@property (retain) NSString* serviceUrl;
@property (retain) NSString* namespace;
@property (retain) NSString* username;
@property (retain) NSString* password;
@property (retain) NSDictionary* headers;
@property BOOL logging;
@property (nonatomic, retain) id<SoapDelegate> defaultHandler;

- (id) initWithUrl: (NSString*) url;
- (id) initWithUsername: (NSString*) username andPassword: (NSString*) password;

@end