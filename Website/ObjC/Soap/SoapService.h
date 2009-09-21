#import "SoapDelegate.h"

@interface SoapService : NSObject
{
	NSString* serviceUrl;
	NSString* namespace;
	NSDictionary* headers;
	BOOL logging;
	id<SoapDelegate> defaultHandler;
}

@property (retain) NSString* serviceUrl;
@property (retain) NSString* namespace;
@property (retain) NSDictionary* headers;
@property BOOL logging;
@property (nonatomic, retain) id<SoapDelegate> defaultHandler;

-(id) initWithUrl: (NSString*) url;

@end