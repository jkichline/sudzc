//
//  SoapReachability.m
//  Vaquero
//
//  Created by Jason Kichline on 9/21/09.
//  Copyright 2009 andCulture. All rights reserved.
//

#import "SoapReachability.h"
#import <netinet/in.h>
#import <netdb.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <unistd.h>

@implementation SoapReachability

+ (BOOL) connectedToNetwork {
	// Create zero address
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	
	// Recover reachability flags
	SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
	SCNetworkReachabilityFlags flags; BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags); CFRelease(defaultRouteReachability);
	if (!didRetrieveFlags) {
		printf("Error. Could not recover network reachability flags\n");
		return 0;
	}
	BOOL isReachable = flags & kSCNetworkFlagsReachable;
	BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	return (isReachable && !needsConnection) ? YES : NO;
}

// Return the localized IP address
+ (NSString*) localIPAddress {
	char baseHostName[255];
	gethostname(baseHostName, 255);
	char hn[255];
	
	// This adjusts for iPhone by adding .local to the host name
	sprintf(hn, "%s.local", baseHostName);
	struct hostent *host = gethostbyname(hn);
	if (host == NULL) {
		herror("resolv");
		return NULL;
	} else {
		struct in_addr **list = (struct in_addr **)(host->h_addr_list);
		return [NSString stringWithCString:inet_ntoa(*list[0]) encoding: NSUTF8StringEncoding];
	}
	return NULL;
}

+ (NSString*) getIPAddressForHost: (NSString*) theHost {
	if(theHost == nil) { return nil; }
	struct hostent *host = gethostbyname([theHost UTF8String]);
	if (host == NULL) {
		herror("resolv");
		return NULL;
	}
	struct in_addr **list = (struct in_addr **)host->h_addr_list;
	NSString *addressString = [NSString stringWithCString:inet_ntoa(*list[0]) encoding: NSUTF8StringEncoding];
	return addressString;
}

+ (BOOL) hostAvailable: (NSString*) theHost {
	NSString *addressString = [SoapReachability getIPAddressForHost:theHost];
	if (!addressString) {
		printf("Error recovering IP address from host name\n");
		return NO;
	}
	
	struct sockaddr_in address;
	BOOL gotAddress = [SoapReachability addressFromString:addressString address:&address];
	if (!gotAddress) {
		printf("Error recovering sockaddr address from %s\n", [addressString UTF8String]);
		return NO;
	}
	
	SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&address);
	SCNetworkReachabilityFlags flags;
	BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
	CFRelease(defaultRouteReachability);
	if (!didRetrieveFlags) {
		printf("Error. Could not recover network reachability flags\n");
		return NO;
	}
	BOOL isReachable = flags & kSCNetworkFlagsReachable;
	return isReachable ? YES : NO;
}

// Populating a sockaddr_in record.
// Direct from Apple. Thank you Apple
+ (BOOL)addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *) address {
	if (!IPAddress || ![IPAddress length]) {
		return NO;
	}
	memset((char *) address, sizeof(struct sockaddr_in), 0);
	address->sin_family = AF_INET;
	address->sin_len = sizeof(struct sockaddr_in);
	int conversionResult = inet_aton([IPAddress UTF8String], &address->sin_addr);
	if (conversionResult == 0) {
		NSAssert1(conversionResult != 1, @"Failed to convert the IP address string ➥into a sockaddr_in: %@", IPAddress);
		return NO;
	}
	return YES;
}

@end
