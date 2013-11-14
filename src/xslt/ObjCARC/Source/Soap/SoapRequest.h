//
//  SoapRequest.h
//
//  Interface definition of the request object used to manage asynchronous requests.
//  Author: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
//

#import "SoapHandler.h"
@class SoapService;

@interface SoapRequest : NSObject

@property(nonatomic, strong) NSURL *url;
@property(nonatomic, strong) NSString *soapAction;
@property(nonatomic, strong) NSString *username;
@property(nonatomic, strong) NSString *password;
@property(nonatomic, strong) id postData;
@property(nonatomic, strong) NSMutableData *receivedData;
@property(nonatomic, strong) NSURLConnection *conn;
@property(nonatomic, strong) SoapHandler *handler;
@property(nonatomic, strong) id deserializeTo;
@property(nonatomic, assign) SEL action;
@property(nonatomic, assign) BOOL logging;
@property(nonatomic, weak) id <SoapDelegate> defaultHandler;

+ (SoapRequest *)create:(SoapHandler *)handler
              urlString:(NSString *)urlString
             soapAction:(NSString *)soapAction
               postData:(NSString *)postData
          deserializeTo:(id)deserializeTo;

+ (SoapRequest *)create:(SoapHandler *)handler
                 action:(SEL)action
              urlString:(NSString *)urlString
             soapAction:(NSString *)soapAction
               postData:(NSString *)postData
          deserializeTo:(id)deserializeTo;

+ (SoapRequest *)create:(SoapHandler *)handler
                 action:(SEL)action
                service:(SoapService *)service
             soapAction:(NSString *)soapAction
               postData:(NSString *)postData
          deserializeTo:(id)deserializeTo;

- (BOOL)cancel;
- (void)send;
- (void)handleError:(NSError *)error;
- (void)handleFault:(SoapFault *)fault;

@end
