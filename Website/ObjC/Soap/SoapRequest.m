/*
 SoapRequest.m
 Implementation of the request object used to manage asynchronous requests.
 Author:	Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
*/

#import "SoapRequest.h"
#import "SoapArray.h"
#import "SoapFault.h"
#import "Soap.h"

@implementation SoapRequest

@synthesize handler, url, soapAction, postData, receivedData, username, password, deserializeTo, action, logging;

// Creates a request to submit from discrete values.
+ (SoapRequest*) create: (SoapHandler*) handler urlString: (NSString*) urlString soapAction: (NSString*) soapAction postData: (NSString*) postData deserializeTo: (id) deserializeTo {
	return [SoapRequest create: handler action: nil urlString: urlString soapAction: soapAction postData: postData deserializeTo: deserializeTo];
}

+ (SoapRequest*) create: (SoapHandler*) handler action: (SEL) action urlString: (NSString*) urlString soapAction: (NSString*) soapAction postData: (NSString*) postData deserializeTo: (id) deserializeTo {
	SoapRequest* request = [[SoapRequest alloc] init];
	request.url = [NSURL URLWithString: urlString];
	request.soapAction = soapAction;
	request.postData = [postData retain];
	request.handler = handler;
	request.deserializeTo = deserializeTo;
	request.action = action;
	return [request autorelease];
}

// Sends the request via HTTP.
- (void) send {
	if(handler == nil) {
		handler = [[SoapHandler alloc] init];
	}
	if(logging) {
		NSLog(url.absoluteString);
	}
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: url];
	
	if(soapAction != nil) {
		[request addValue: soapAction forHTTPHeaderField: @"SOAPAction"];
	}
	if(postData != nil) {
		[request setHTTPMethod: @"POST"];
		[request addValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
		[request setHTTPBody: [postData dataUsingEncoding: NSUTF8StringEncoding]];
		if(self.logging) {
			NSLog([NSString stringWithFormat: @"%@", postData]);
		}
	}
	
	conn = [[NSURLConnection alloc] initWithRequest: request delegate: self];
	if(conn) {
		receivedData = [[NSMutableData data] retain];
	} else {
		// We will want to call the onerror method selector here...
		if(self.handler != nil) {
			NSError* error = [NSError errorWithDomain:@"SoapRequest" code:404 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"Could not create connection", NSLocalizedDescriptionKey]];
			SEL onerror = @selector(onerror:);
			if(self.action != nil) { onerror = self.action; }
			if([self.handler respondsToSelector: onerror]) {
				[self.handler performSelector: onerror withObject: error];
			}
		}
	}
}

// Called when the HTTP socket gets a response.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.receivedData setLength:0];
}

// Called when the HTTP socket received data.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)value {
    [self.receivedData appendData:value];
}

// Called when the HTTP request fails.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[conn release];
	[self.receivedData release];
	if([self.handler respondsToSelector:@selector(onerror:)]) {
		[self.handler onerror:error];
	}
	if(self.logging) {
		NSLog(error.localizedDescription);
	}
}

// Called when the connection has finished loading.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSError* error;
	if(self.logging == YES) {
		NSString* response = [[NSString alloc] initWithData: self.receivedData encoding: NSUTF8StringEncoding];
		NSLog(response);
		[response release];
	}

	CXMLDocument* doc = [[CXMLDocument alloc] initWithData: self.receivedData options: 0 error: &error];
	if(doc == nil) {
		if([self.handler respondsToSelector:@selector(onerror:)]) {
			[self.handler onerror: error];
		}
		if(self.logging) {
			NSLog(error.localizedDescription);
		}
		return;
	}

	id output = nil;
	SoapFault* fault = [SoapFault faultWithXMLDocument: doc];

	if([fault hasFault]) {
		if(self.action == nil) {
			if([self.handler respondsToSelector:@selector(onfault:)]) {
				[self.handler onfault: fault];
			}
			if(self.logging) {
				NSLog([NSString stringWithFormat:@"%@", fault]);
			}
		} else {
			output = fault;
		}
	} else {
		if(deserializeTo == nil) {
			output = nil;
		} else {
			CXMLNode* element = [[Soap getNode: [doc rootElement] withName: @"Body"] childAtIndex:0];
			if(deserializeTo != nil) {
				if([deserializeTo respondsToSelector: @selector(initWithNode:)]) {
					element = [element childAtIndex:0];
					output = [deserializeTo initWithNode: element];
				} else {
					NSString* value = [[[element childAtIndex:0] childAtIndex:0] stringValue];
					output = [Soap convert: value toType: deserializeTo];
				}
			}
		}
		
		if(self.action == nil) { self.action = @selector(onload:); }
		if(self.handler != nil && [self.handler respondsToSelector: self.action]) {
			[self.handler performSelector: self.action withObject: output];
		}
	}

	[self.handler release];
	[doc release];
	[conn release];
	[self.receivedData release];
}

// Called if the HTTP request receives an authentication challenge.
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if([challenge previousFailureCount] == 0) {
		NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
		NSError* error = [NSError errorWithDomain:@"SoapRequest" code:403 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"Could not authenticate this request", NSLocalizedDescriptionKey]];
		[handler onerror: error];
    }
}

// Cancels the HTTP request.
- (BOOL) cancel {
	if(conn == nil) { return NO; }
	[conn cancel];
	[conn release];
	return YES;
}

// Deallocates the object
- (void) dealloc {
	[url release];
	[soapAction release];
	[username release];
	[password release];
	[deserializeTo release];
	[postData release];
	[super dealloc];
}

@end