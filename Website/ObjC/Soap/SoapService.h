@interface SoapService : NSObject
{
	NSString* serviceUrl;
	NSString* namespace;
	NSDictionary* headers;
	BOOL logging;
}

	@property (retain) NSString* serviceUrl;
	@property (retain) NSString* namespace;
	@property (retain) NSDictionary* headers;
	@property BOOL logging;
	
	- (id) initWithUrl: (NSString*) url;

@end