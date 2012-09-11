//
//  SoapReachability.h
//  Vaquero
//
//  Created by Jason Kichline on 9/21/09.
//  Copyright 2009 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

@interface SoapReachability : NSObject {

}

// Determines if we are connected to the network
+ (BOOL) connectedToNetwork;

// Gets the local IP address
+ (NSString*) localIPAddress;

// Gets an IP address for a host
+ (NSString*) getIPAddressForHost: (NSString*) theHost;

// Determines if a host is available
+ (BOOL) hostAvailable: (NSString*) theHost;

// Gets an address from the string
+ (BOOL)addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *) address;

@end
