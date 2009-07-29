#import "SoapService.h"

@implementation SoapService

	@synthesize serviceUrl, namespace, logging, headers;

	- (id) initWithUrl: (NSString*) url
	{
		if(self = [self init])
		{
			self.serviceUrl = url;
		}
		return self;
	}
	
@end