//
//  SoapService.h
//
//  Author: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
//

#import "SoapDelegate.h"

@interface SoapService : NSObject

@property (nonatomic, strong) NSString *serviceUrlString;
@property (nonatomic, strong) NSString *serviceNamespace;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, assign) BOOL logging;
@property (nonatomic, weak) id <SoapDelegate> defaultHandler;

- (id)initWithUrlString:(NSString *)urlString;
- (id)initWithUsername:(NSString *)username andPassword:(NSString *)password;

@end
