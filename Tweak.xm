#import <Preferences/PSListController.h>
#import <version.h>
#import <notify.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_9_2
#define kCFCoreFoundationVersionNumber_iOS_9_2 1242.13
#endif

@interface PSListController (PullToRespring)
- (id)table;
@end

@interface PrefsListController : PSListController
@end
@interface PSUIPrefsListController : PSListController
@end

@interface SpringBoard : UIApplication
- (void)_relaunchSpringBoardNow;
@end

@interface FBSystemService : NSObject
+ (id)sharedInstance;
- (void)exitAndRelaunch:(BOOL)arg1;
@end

@interface PTRRespringHandler : NSObject
@property (nonatomic, assign) PSListController *listController;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
+ (instancetype)sharedInstance;
- (void)refreshControlValueChangedFORDAYS:(UIRefreshControl *)refreshControl;
- (void)updateRefreshControlExistence:(BOOL)shouldExist;
@end

// Take PSListController argument so we can add the refresh control to the view
static UIRefreshControl *createRefreshControlWithListController(PSListController *listController) {
	// Remove previous if existing
    [PTRRespringHandler.sharedInstance updateRefreshControlExistence:NO];
    // Instantiate new refresh control
    UIRefreshControl *refreshControl = [UIRefreshControl new];
	[refreshControl addTarget:[PTRRespringHandler sharedInstance] action:@selector(refreshControlValueChangedFORDAYS:) forControlEvents:UIControlEventValueChanged];
    // Setup property references
    PTRRespringHandler.sharedInstance.listController = listController;
    PTRRespringHandler.sharedInstance.refreshControl = refreshControl;
	// Return refreshControl
	return refreshControl;
}

static void loadPreferences() {
	// Sync preferences and retrieve
	CFPreferencesAppSynchronize(CFSTR("com.sassoty.pulltorespring"));
	id isEnabledVal = (id)CFPreferencesCopyAppValue(CFSTR("Enabled"), CFSTR("com.sassoty.pulltorespring"));
    // Have the controller update the existence of the refresh control
    [PTRRespringHandler.sharedInstance updateRefreshControlExistence:(isEnabledVal ? [isEnabledVal boolValue] : YES)];
}

// iOS 8 & 7
%hook PrefsListController
- (void)viewDidAppear:(BOOL)animated {
	%orig;
    [self.table addSubview:createRefreshControlWithListController(self)];
    loadPreferences();
}
%end // End of PrefsListController

// iOS 9 +
%hook PSUIPrefsListController
- (void)viewDidAppear:(BOOL)animated {
	%orig;
    [self.table addSubview:createRefreshControlWithListController(self)];
    loadPreferences();
}
%end // End of PSUIPrefsListController

@implementation PTRRespringHandler

+ (instancetype)sharedInstance {
	static PTRRespringHandler *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [PTRRespringHandler new];
	});
	return sharedInstance;
}

- (void)refreshControlValueChangedFORDAYS:(UIRefreshControl *)refreshControl {
	[refreshControl endRefreshing];
	if(IS_IOS_OR_NEWER(iOS_9_2)) {
		// Send notification to relaunch from SpringBoard
		notify_post("com.sassoty.pulltorespring.relaunchsb");
	}else {
		// Respring directly from SpringBoard instance
		[(SpringBoard *)[UIApplication sharedApplication] _relaunchSpringBoardNow];
	}
}

- (void)updateRefreshControlExistence:(BOOL)shouldExist {
    if(shouldExist) {
        [self.listController.table addSubview:createRefreshControlWithListController(self.listController)];
    }else {
        if(self.refreshControl) {
            [self.refreshControl removeFromSuperview];
        }
    }
}

@end

// SpringBoard listens for a notification because we must call this WITHIN the SpringBoard process
static void relaunchSpringBoard() {
	[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

%ctor {
	// Preferences app
	if([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.Preferences"]) {
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
					(CFNotificationCallback)loadPreferences,
					CFSTR("com.sassoty.pulltorespring.prefschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	// SpringBoard process
	}else if([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
					(CFNotificationCallback)relaunchSpringBoard,
					CFSTR("com.sassoty.pulltorespring.relaunchsb"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	}
}
