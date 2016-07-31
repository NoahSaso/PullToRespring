#import <Preferences/PSListController.h>
#import <version.h>
#import <notify.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_9_2
#define kCFCoreFoundationVersionNumber_iOS_9_2 1242.13
#endif

@interface PSListController (PullToRespring)
+ (id)sharedInstance;
- (UIRefreshControl *)initiateRefreshControl;
@end

@interface PrefsListController : PSListController
- (UIRefreshControl *)initiateRefreshControl;
+ (id)sharedInstance;
- (id)table;
@end

@interface SpringBoard : UIApplication
- (void)_relaunchSpringBoardNow;
@end

@interface FBSystemService : NSObject
+ (id)sharedInstance;
- (void)exitAndRelaunch:(BOOL)arg1;
@end

static UIRefreshControl *refreshControl = nil;
static BOOL enabled = YES;

static PSListController *listController = nil;

static void createRefreshControl() {
	// If we don't have an instance of the prefs list, we can't do anything
    if(!listController) return;
    // If refreshControl exists, remove it so we can readd
    if(refreshControl) [refreshControl removeFromSuperview];
    // Reinstantiate new refresh control
    refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:listController action:@selector(respringForDays) forControlEvents:UIControlEventValueChanged];
    // Add to table -- table handles refresh control subviews automatically
    [[listController table] addSubview:refreshControl];
}

static void loadPreferences() {
	// Use previous value to see if we have to add it while in-app
    BOOL prevEnabled = enabled;
    // Sync preferences and retrieve
    CFPreferencesAppSynchronize(CFSTR("com.sassoty.pulltorespring"));
    id enabledVal = (id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.sassoty.pulltorespring"));
    // If not set, default to being enabled
    enabled = enabledVal ? [enabledVal boolValue] : YES;
    if (enabled) {
        HBLogDebug(@"[PullToRespring] We are enabled");
        // If was previously disabled, add to list right away (instantaneous effect)
        if(!prevEnabled)
            createRefreshControl();
    } else {
        HBLogDebug(@"[PullToRespring] We are NOT enabled");
        // Remove if we're disabling it (instantaneous effect)
        if(refreshControl) [refreshControl removeFromSuperview];
    }
}

// iOS 8
%group BelowiOS9
%hook PrefsListController

- (id)init {
    listController = %orig;
    return listController;
}

- (void)viewDidAppear:(BOOL)view {
	%orig;
    createRefreshControl();
}

%new - (void)respringForDays {
    HBLogDebug(@"[PullToRespring] Respringing...");
    [refreshControl endRefreshing];
    [(SpringBoard *)[UIApplication sharedApplication] _relaunchSpringBoardNow];
}

%end // End of PrefsListController
%end // End of BelowiOS9

// iOS 9

@interface PSUIPrefsListController : PSListController
- (UIRefreshControl *)initiateRefreshControl;
- (void)respringForDays;
@end

%hook PSUIPrefsListController

- (id)init {
    listController = %orig;
    return listController;
}

- (void)viewDidAppear:(BOOL)view {
    %orig;
    createRefreshControl();
}

%group iOS91Below
%new - (void)respringForDays {
    HBLogDebug(@"[PullToRespring] Respringing...");
    [refreshControl endRefreshing];
    [(SpringBoard *)[UIApplication sharedApplication] _relaunchSpringBoardNow];
}
%end // End of iOS91Below
%group iOS92Up
%new - (void)respringForDays {
    HBLogDebug(@"[PullToRespring] Respringing...");
    [refreshControl endRefreshing];
    // Send notification to relaunch from SpringBoard
    notify_post("com.sassoty.pulltorespring.relaunchsb");
}
%end // End of iOS92Up
%end // End of PSUIPrefsListController

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
    	    loadPreferences();

    	if(IS_IOS_OR_NEWER(iOS_9_2)) {
    		%init(iOS92Up);
    	// iOS 9.2 won't be included in this because it would've gotten caught in the first if
    	}else if(IS_IOS_BETWEEN(iOS_9_0, iOS_9_2)) {
    		%init(iOS91Below);
    	}else {
    	    %init(BelowiOS9);
    	}

    	// No groups inside groups, but we can have initialize ungrouped stuff too
    	if(IS_IOS_OR_NEWER(iOS_9_0)) {
    		%init;
    	}
    // SpringBoard process
    }else if([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
    	    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
    				(CFNotificationCallback)relaunchSpringBoard,
    				CFSTR("com.sassoty.pulltorespring.relaunchsb"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }

}
