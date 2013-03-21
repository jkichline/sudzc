//
//  SoapService.m
//
//  Author: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
//

#import "SoapService.h"

@implementation SoapService

- (id)init
{
    self = [super init];
    if (self) {
        _serviceUrlString = nil;
        _serviceNamespace = nil;
        _headers = nil;
        _username = nil;
        _password = nil;
        _logging = NO;
        _defaultHandler = nil;
    }
    return self;
}

- (id)initWithUrlString:(NSString *)urlString
{
    self = [self init];
    if (self) {
        _serviceUrlString = urlString;
    }
    return self;
}

- (id)initWithUsername:(NSString *)username andPassword:(NSString *)password
{
    self = [self init];
    if (self) {
        _username = username;
        _password = password;
    }
    return self;
}

@end
