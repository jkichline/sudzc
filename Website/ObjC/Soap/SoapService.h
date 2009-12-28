#import "SoapDelegate.h"

@interface SoapService : NSObject
{
	NSString* serviceUrl;
	NSString* namespace;
	NSString* username;
	NSString* password;
	NSDictionary* headers;
	BOOL logging;
	id<SoapDelegate> defaultHandler;
}

@property (retain) NSString* serviceUrl;
@property (retain) NSString* namespace;
@property (retain) NSString* username;
@property (retain) NSString* password;
@property (retain) NSDictionary* headers;
@property BOOL logging;
@property (nonatomic, retain) id<SoapDelegate> defaultHandler;

-(id) initWithUrl: (NSString*) url;

@end