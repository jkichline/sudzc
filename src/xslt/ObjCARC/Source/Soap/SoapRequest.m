//
//  SoapRequest.m
//
//  Interface definition of the request object used to manage asynchronous requests.
//  Author: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
//

#import "SoapRequest.h"
#import "SoapArray.h"
#import "Soap.h"
#import <objc/message.h>

@implementation SoapRequest

// Creates a request to submit from discrete values.
+ (SoapRequest *)create:(SoapHandler *)aHandler
              urlString:(NSString *)anUrlString
             soapAction:(NSString *)aSoapAction
               postData:(NSString *)somePostData
          deserializeTo:(id)deserializeTo
{
    return [SoapRequest create:aHandler
                        action:nil urlString:anUrlString
                    soapAction:aSoapAction
                      postData:somePostData
                 deserializeTo:deserializeTo];
}

+ (SoapRequest *)create:(SoapHandler *)aHandler
                 action:(SEL)anAction
              urlString:(NSString *)anUrlString
             soapAction:(NSString *)aSoapAction
               postData:(NSString *)somePostData
          deserializeTo:(id)deserializeTo
{
    SoapRequest *request = [[SoapRequest alloc] init];

    request.url = [NSURL URLWithString:anUrlString];
    request.soapAction = aSoapAction;
    request.postData = somePostData;
    request.handler = aHandler;
    request.deserializeTo = deserializeTo;
    request.action = anAction;
    request.defaultHandler = nil;

    return request;
}

+ (SoapRequest *)create:(SoapHandler *)aHandler
                 action:(SEL)anAction
                service:(SoapService *)aService
             soapAction:(NSString *)aSoapAction
               postData:(NSString *)somePostData
          deserializeTo:(id)deserializeTo
{
    SoapRequest *request = [SoapRequest create:aHandler
                                        action:anAction
                                     urlString:aService.serviceUrlString
                                    soapAction:aSoapAction
                                      postData:somePostData
                                 deserializeTo:deserializeTo];

    request.defaultHandler = aService.defaultHandler;
    request.logging = aService.logging;
    request.username = aService.username;
    request.password = aService.password;

    return request;
}

// Sends the request via HTTP.
- (void)send
{
    // If we don't have a handler, create a default one
    if (self.handler == nil) {
        self.handler = [[SoapHandler alloc] init];
    }

    // Make sure the network is available
    if ([SoapReachability connectedToNetwork] == NO) {
        NSError *error = [NSError errorWithDomain:@"SudzC"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"The network is not available"}];
        [self handleError:error];
    }

    // Make sure we can reach the host
    if ([SoapReachability hostAvailable:self.url.host] == NO) {
        NSError *error = [NSError errorWithDomain:@"SudzC"
                                             code:410
                                         userInfo:@{NSLocalizedDescriptionKey: @"The host is not available"}];
        [self handleError:error];
    }

    // Output the URL if logging is enabled
    if (self.logging) {
        NSLog(@"Loading: %@", self.url.absoluteString);
    }

    // Create the request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
    if (self.soapAction != nil) {
        [request addValue:self.soapAction forHTTPHeaderField:@"SOAPAction"];
    }

    if (self.postData != nil) {
        [request setHTTPMethod:@"POST"];
        [request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[self.postData dataUsingEncoding:NSUTF8StringEncoding]];

        if (self.logging) {
            NSLog(@"%@", self.postData);
        }
    }

    // Create the connection
    NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    self.conn = aConnection;
    if (self.conn) {
        self.receivedData = [NSMutableData data];
    } else {
        // We will want to call the onerror method selector here...
        if (self.handler != nil) {
            NSError *error = [NSError errorWithDomain:@"SoapRequest"
                                                 code:404
                                             userInfo:@{NSLocalizedDescriptionKey: @"Could not create connection"}];
            [self handleError:error];
        }
    }
}

- (void)handleError:(NSError *)error
{
    SEL onerror = @selector(onerror:);
    if (self.action != nil) {
        onerror = self.action;
    }
    if ([self.handler respondsToSelector:onerror]) {
        objc_msgSend(self.handler, onerror, error);
    } else {
        if (self.defaultHandler != nil && [self.defaultHandler respondsToSelector:onerror]) {
            objc_msgSend(self.defaultHandler, onerror, error);
        }
    }
    if (self.logging) {
        NSLog(@"Error: %@", error.localizedDescription);
    }
}

- (void)handleFault:(SoapFault *)fault
{
    if ([self.handler respondsToSelector:@selector(onfault:)]) {
        [self.handler onfault:fault];
    } else if (self.defaultHandler != nil && [self.defaultHandler respondsToSelector:@selector(onfault:)]) {
        [self.defaultHandler onfault:fault];
    }

    if (self.logging) {
        NSLog(@"Fault: %@", fault);
    }
}

// Called when the HTTP socket gets a response.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.receivedData setLength:0];
}

// Called when the HTTP socket received data.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)value
{
    [self.receivedData appendData:value];
}

// Called when the HTTP request fails.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.conn = nil;
    [self handleError:error];
}

// Called when the connection has finished loading.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error = nil;
    if (self.logging == YES) {
        NSString *response = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", response);
    }

    CXMLDocument *doc = [[CXMLDocument alloc] initWithData:self.receivedData options:0 error:&error];
    if (doc == nil) {
        [self handleError:error];
        return;
    }

    id output = nil;
    SoapFault *fault = [SoapFault faultWithXMLDocument:doc];
    if ([fault hasFault]) {
        if (self.action == nil) {
            [self handleFault:fault];
        } else {
            if (self.handler != nil && [self.handler respondsToSelector:self.action]) {
                objc_msgSend(self.handler, self.action, fault);
            } else {
                NSLog(@"SOAP Fault: %@", fault);
            }
        }
    }
    else {
        CXMLNode *element = [[Soap getNode:[doc rootElement] withName:@"Body"] childAtIndex:0];
        if (self.deserializeTo == nil) {
            output = [Soap deserialize:element];
        } else {
            if ([self.deserializeTo respondsToSelector:@selector(initWithNode:)]) {
                element = [element childAtIndex:0];
                output = [self.deserializeTo initWithNode:element];
            } else {
                NSString *value = [[[element childAtIndex:0] childAtIndex:0] stringValue];
                output = [Soap convert:value toType:self.deserializeTo];
            }
        }

        if (self.action == nil) {
            self.action = @selector(onload:);
        }

        if (self.handler != nil && [self.handler respondsToSelector:self.action]) {
            objc_msgSend(self.handler, self.action, output);
        } else if (self.defaultHandler != nil && [self.defaultHandler respondsToSelector:@selector(onload:)]) {
            [self.defaultHandler onload:output];
        }
    }
    self.conn = nil;
}

// WARNING (macadamian): Added method below
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return YES;
}

// Called if the HTTP request receives an authentication challenge.
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] == 0) {
        NSURLCredential *newCredential = [NSURLCredential credentialWithUser:self.username
                                                                    password:self.password
                                                                 persistence:NSURLCredentialPersistenceNone];

        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
    }
    else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        NSError *error = [NSError errorWithDomain:@"SoapRequest"
                                             code:403
                                         userInfo:@{ NSLocalizedDescriptionKey: @"Could not authenticate this request" }];
        [self handleError:error];
    }
}

// Cancels the HTTP request.
- (BOOL)cancel
{
    if (self.conn == nil) {
        return NO;
    }

    [self.conn cancel];
    return YES;
}

@end
