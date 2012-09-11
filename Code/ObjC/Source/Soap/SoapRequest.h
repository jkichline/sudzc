/*
 SoapRequest.h
 Interface definition of the request object used to manage asynchronous requests.
 Author:	Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
*/

#import "SoapHandler.h"
#import "SoapService.h"

@interface SoapRequest : NSObject {
	NSURL* url;
	NSString* soapAction;
	NSString* username;
	NSString* password;
	id postData;
	NSMutableData* receivedData;
	NSURLConnection* conn;
	SoapHandler* handler;
	id deserializeTo;
	SEL action;
	BOOL logging;
	id<SoapDelegate> defaultHandler;
}

@property (retain, nonatomic) NSURL* url;
@property (retain, nonatomic) NSString* soapAction;
@property (retain, nonatomic) NSString* username;
@property (retain, nonatomic) NSString* password;
@property (retain, nonatomic) id postData;
@property (retain, nonatomic) NSMutableData* receivedData;
@property (retain, nonatomic) SoapHandler* handler;
@property (retain, nonatomic) id deserializeTo;
@property SEL action;
@property BOOL logging;
@property (retain, nonatomic) id<SoapDelegate> defaultHandler;

+ (SoapRequest*) create: (SoapHandler*) handler urlString: (NSString*) urlString soapAction: (NSString*) soapAction postData: (NSString*) postData deserializeTo: (id) deserializeTo;
+ (SoapRequest*) create: (SoapHandler*) handler action: (SEL) action urlString: (NSString*) urlString soapAction: (NSString*) soapAction postData: (NSString*) postData deserializeTo: (id) deserializeTo;
+ (SoapRequest*) create: (SoapHandler*) handler action: (SEL) action service: (SoapService*) service soapAction: (NSString*) soapAction postData: (NSString*) postData deserializeTo: (id) deserializeTo;

- (BOOL)cancel;
- (void)send;
- (void)handleError:(NSError*)error;
- (void)handleFault:(SoapFault*)fault;

@end