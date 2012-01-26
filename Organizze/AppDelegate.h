//
//  AppDelegate.h
//  Organizze
//
//  Created by Cassio Rossi on 11/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

@interface AppDelegate : NSObject <UIApplicationDelegate, UINavigationControllerDelegate> {
	UIButton	*syncCancelButton, *netCancelButton;
	UILabel		*syncTitleLabel, *syncMessageLabel;
	UIImageView	*syncLeftArrow, *syncRightArrow;
	UIView		*osNotSupportedView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, assign) IBOutlet UIView *osNotSupportedView;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, assign) IBOutlet UIView *networkErrorMessageView, *syncView;
@property (nonatomic, assign) IBOutlet UIButton *syncCancelButton, *netCancelButton;
@property (nonatomic, assign) IBOutlet UILabel *syncTitleLabel, *syncMessageLabel;
@property (nonatomic, assign) IBOutlet UIImageView *syncLeftArrow, *syncRightArrow;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory:(NSString *)filename;

- (void)showNetworkMessageWithCancelButton:(BOOL)canCancel;
- (void)showSyncMessage:(BOOL)show withMessages:(NSDictionary *)syncInfo;
- (IBAction)hideMessages:(id)sender;
- (void)initializeApp;

@end
