//
//  networkMethods.m
//
//  Created by Cassio on 8/16/10.
//  Copyright 2010 Kazzio Software. All rights reserved.
//

#import "networkMethods.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

static id sharedInstance;

@implementation networkMethods

@synthesize delegate;

#pragma mark -
#pragma mark Singleton Methods

/**
 Function	: shared
 Return		: void
 Arguments	: none
 Example	: [networkMethods shared];
 Explanation: this function initialize the class. Should be called for every function inside it.
 
 2010/08/16 – Cassio
 – Creation of the function
 */
+ (id)shared {
	if (sharedInstance == nil) {
		sharedInstance = [[networkMethods alloc] init];
	}
	return sharedInstance;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark -
#pragma mark General Methods

- (BOOL)addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *)address {
	if (!IPAddress || ![IPAddress length]) {
		return NO;
	}
	
	memset((char *)address, 0, sizeof(struct sockaddr_in));
	address->sin_family = AF_INET;
	address->sin_len = sizeof(struct sockaddr_in);
	
	int conversionResult = inet_aton([IPAddress UTF8String], &address->sin_addr);
	
	if (conversionResult == 0) {
		//NSAssert1(conversionResult != 1, @"Failed to convert the IP address string into a sockaddr_in: %@", IPAddress);
		return NO;
	}
	
	return YES;
}

- (void)checkHostAvailability:(NSString *)host {
	struct sockaddr_in ip;
	if ([self addressFromString:host address:&ip]) {
		hostReach = [[Reachability reachabilityWithAddress:&ip] retain];
		[self updateInterfaceWithReachability:hostReach];
	} else {
		hostReach = [[Reachability reachabilityWithHostName:host] retain];
	}
	
	[hostReach startNotifier];
}

- (void)networkStatusChanged:(BOOL)networkIsAvailable {
	// Check to see if there is a delegate to responde to the method
	if (delegate && [delegate respondsToSelector:@selector(networkStatusChanged:)]) {
		[delegate networkStatusChanged:networkIsAvailable];
	}
}

- (BOOL)reachableViaWiFi {
	return ([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] == ReachableViaWiFi);
}

#pragma mark -
#pragma mark Notification methods

// Callback para a função de detecção de rede
- (void)updateInterfaceWithReachability:(Reachability *)curReach {
	BOOL networkIsAvailable = NO;
	
	if (curReach == hostReach) {
		NetworkStatus netStatus = [curReach currentReachabilityStatus];
		
		switch (netStatus) {
			case NotReachable:			// NSLog(@"Access Not Available");
				networkIsAvailable = NO;
				break;
				
			case ReachableViaWWAN:		// NSLog(@"Reachable WWAN");
			case ReachableViaWiFi:		// NSLog(@"Reachable WiFi");
				networkIsAvailable = YES;
				break;
		}
		
		// Manda mensagem para o parent, avisando que os dados estão disponíveis
		[self networkStatusChanged:networkIsAvailable];
	}
}

- (void)stopNetworkNotifer {
	[hostReach stopNotifier];
}

@end
