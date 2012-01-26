//
//  AppDelegate.m
//  Organizze
//
//  Created by Cassio Rossi on 11/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

#import "AppDelegate.h"
#import "Movimentacoes_ViewController.h"
#import "SFHFKeychainUtils.h"
#import "Password_ViewController.h"
#import "Login_ViewController.h"

@implementation AppDelegate

#pragma mark - @synthesize

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize osNotSupportedView;

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

@synthesize networkErrorMessageView, netCancelButton;
@synthesize syncView, syncCancelButton, syncTitleLabel, syncMessageLabel, syncLeftArrow, syncRightArrow;

#pragma mark - Memory Management

- (void)dealloc {
	[_window release];
	[_navigationController release];
	
	[__managedObjectContext release];
	[__managedObjectModel release];
	[__persistentStoreCoordinator release];
	
	[super dealloc];
}

#pragma mark - Application Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Supported version: iOS4+
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(scheduleLocalNotification:)]) {
		// Override point for customization after application launch.
		self.syncLeftArrow.transform = CGAffineTransformRotate(self.syncLeftArrow.transform, -M_PI);

		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];

		if ([[NSUserDefaults standardUserDefaults] objectForKey:@"CREDENTIALS"] != nil) {
			// Lê a senha armazenada no Keychain. Se existe (4 digitos), pede a senha ao usuário
			NSString *password = [SFHFKeychainUtils getPasswordForUsername:@"organizze" andServiceName:@"omz:software Organizze" error:NULL];
			if ([password length] == 4) {
				Password_ViewController *anotherViewController = [[[Password_ViewController alloc] initWithNibName:@"Password_ViewController" bundle:nil] autorelease];
				anotherViewController.askForPassword = NO;
				[self.window setRootViewController:anotherViewController];
				anotherViewController = nil;
			} else {
				[self initializeApp];
			}
		} else {
			[self initializeApp];

			Login_ViewController *detailViewController = [[Login_ViewController alloc] initWithStyle:UITableViewStyleGrouped];
			detailViewController.firstTime = YES;
			[self.navigationController presentModalViewController:detailViewController animated:YES];
			[detailViewController release];
		}
	} else {
		// Add View to request Update
		[self.window addSubview:self.osNotSupportedView];
	}
	
	[self.window makeKeyAndVisible];

	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
/*
Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
*/
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
/*
Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
*/
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
/*
Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
*/
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
/*
Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
*/
}

- (void)applicationWillTerminate:(UIApplication *)application {
// Saves changes in the application's managed object context before the application terminates.
	[self saveContext];
}

- (void)saveContext {
	NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	if (managedObjectContext != nil) {
		if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
		} 
	}
}

#pragma mark - UINavigationController Delegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	// Antes de inserir a subview, verificar se já existe ...
	if (![[CUSTOMNAVBAR objectForKey:@"IMAGEM"] isEqualToString:@""]) {
		if ([navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)] ) {
			//iOS 5 new UINavigationBar custom background
			[navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:[CUSTOMNAVBAR objectForKey:@"IMAGEM"]] forBarMetrics:UIBarMetricsDefault];
		} else {
			// Tratamento por imagem
			UIImageView *imageView = (UIImageView *)[navigationController.navigationBar viewWithTag:5555];
			if (imageView == nil) {
				imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[CUSTOMNAVBAR objectForKey:@"IMAGEM"]]];
				[imageView setFrame:CGRectMake(0, 0, 320, 44)];
				[imageView setTag:5555];
				[navigationController.navigationBar insertSubview:imageView atIndex:0];
				[imageView release];
			} else {
				[navigationController.navigationBar sendSubviewToBack:imageView];
			}
		}
	}

	if (![[CUSTOMNAVBAR objectForKey:@"COR"] isEqualToString:@""]) {
		// Tratamento por cor
		[navigationController.navigationBar setTintColor:[[sharedMethods shared] colorWithHexString:[CUSTOMNAVBAR objectForKey:@"COR"]]];
	}
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
	if (__managedObjectContext != nil) {
		return __managedObjectContext;
	}

	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		__managedObjectContext = [[NSManagedObjectContext alloc] init];
		[__managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
	if (__managedObjectModel != nil) {
		return __managedObjectModel;
	}

	if ([[NSBundle mainBundle] respondsToSelector:@selector(URLForResource:withExtension:)]) {
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Organizze" withExtension:@"momd"];
		__managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
	} else {
		__managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
	}
	return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (__persistentStoreCoordinator != nil) {
		return __persistentStoreCoordinator;
	}

	NSURL *storeURL = [self applicationDocumentsDirectory:@"Organizze.sqlite"];

	// if you make changes to your model and a database already exist in the app
	// you'll get a NSInternalInconsistencyException exception. When the model i updated 
	// the databasefile must be removed. I'll always remove the database here because it is simple.

	NSError *error = nil;
	__persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:  
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,  
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];  
	

	if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}    
	options = nil;

	return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory:(NSString *)filename {
	NSURL *returnValue;

	if ([[NSFileManager defaultManager] respondsToSelector:@selector(URLsForDirectory:inDomains:)]) {
		returnValue = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
		returnValue = [returnValue URLByAppendingPathComponent:filename];
	} else {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
		basePath = [basePath stringByAppendingPathComponent: @"Locations.sqlite"];
		returnValue = [NSURL fileURLWithPath:basePath];
		basePath = nil; paths = nil;
	}
	return returnValue;
}

#pragma mark - Main Methods

- (void)initializeApp {
/*
	Movimentacoes_ViewController *rootViewController = (Movimentacoes_ViewController *)[self.navigationController topViewController];
	rootViewController.managedObjectContext = self.managedObjectContext;
	rootViewController = nil;
*/
	[self.window setRootViewController:self.navigationController];
}

- (IBAction)hideMessages:(id)sender {
	UIButton *btn = (UIButton *)sender;
	if ([btn superview] == self.networkErrorMessageView) {
		[self.networkErrorMessageView removeFromSuperview];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NONETWORKNOTIFICATION" object:nil];
	}
	if ([btn superview] == self.syncView) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ABORTSYNC" object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOWPASSWORDKEYBOARD" object:nil];
		[self.syncView removeFromSuperview];
	}
	btn = nil;
}

- (void)showNetworkMessageWithCancelButton:(BOOL)canCancel {
	[netCancelButton setHidden:!canCancel];
	[self.window addSubview:self.networkErrorMessageView];
	[self.window bringSubviewToFront:self.networkErrorMessageView];
}

#define STARTPOINT	150
#define ENDPOINT	185

- (void)showSyncMessage:(BOOL)show withMessages:(NSDictionary *)syncInfo {
	if (show) {
		[self.syncTitleLabel setText:[syncInfo objectForKey:@"title"]];
		[self.syncMessageLabel setText:[syncInfo objectForKey:@"message"]];
		[self.syncCancelButton setHidden:![[syncInfo objectForKey:@"showCancel"] boolValue]];
		[self.syncLeftArrow setHidden:![[syncInfo objectForKey:@"showArrow"] boolValue]];
		[self.syncRightArrow setHidden:![[syncInfo objectForKey:@"showArrow"] boolValue]];

		[self.window addSubview:self.syncView];
		[self.window bringSubviewToFront:self.syncView];

		CGRect leftArrowRect = self.syncLeftArrow.frame;
		leftArrowRect.origin.x = STARTPOINT;
		CGRect rightArrowRect = self.syncRightArrow.frame;
		rightArrowRect.origin.x = ENDPOINT;

		[UIView animateWithDuration:0.8f
							  delay:0
							options:UIViewAnimationOptionRepeat
						 animations:^{
							 [self.syncLeftArrow setFrame:leftArrowRect];
							 [self.syncLeftArrow setAlpha:0];
							 [self.syncRightArrow setFrame:rightArrowRect];
							 [self.syncRightArrow setAlpha:0];
						 }
						 completion:nil
		 ];

	} else {
		[self.syncView removeFromSuperview];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOWPASSWORDKEYBOARD" object:nil];
	}
}

@end
