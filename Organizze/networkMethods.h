//
//  networkMethods.h
//
//  Created by Cassio on 8/16/10.
//  Copyright 2010 Kazzio Software. All rights reserved.
//

#import "Reachability.h"

@protocol networkMethodsDelegate;

@interface networkMethods : NSObject {
	id <networkMethodsDelegate>  delegate;
    Reachability				*hostReach;
}

@property (nonatomic, assign) id delegate;

+ (id)shared;
- (BOOL)addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *)address;
- (void)updateInterfaceWithReachability:(Reachability *)curReach;
- (void)checkHostAvailability:(NSString *)host;
- (void)stopNetworkNotifer;
- (void)networkStatusChanged:(BOOL)networkIsAvailable;
- (BOOL)reachableViaWiFi;

@end


@protocol networkMethodsDelegate <NSObject>

@optional
- (void)networkStatusChanged:(BOOL)networkIsAvailable;

@end
