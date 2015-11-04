#import <Preferences/Preferences.h>
#import "iOSVersion.m"

@interface PSListController (PullToRespring)
+ (id)sharedInstance;
- (UIRefreshControl *)initiateRefreshControl;
@end

@interface PrefsListController : PSListController
- (UIRefreshControl *)initiateRefreshControl;
+ (id)sharedInstance;
- (id)table;
@end

static UIRefreshControl *refreshControl = nil;
static BOOL enabled = YES;

static PSListController *listController = nil;

static void createRefreshControl() {
    if(!listController) return;
    if(refreshControl) [refreshControl removeFromSuperview];
    refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:listController action:@selector(respringForDays) forControlEvents:UIControlEventValueChanged];
    [[listController table] addSubview:refreshControl];
}

static void loadPreferences() {
    //Get previous value of enabled to see if value changed
    BOOL prevEnabled = enabled;
    //Preference stuff
    CFPreferencesAppSynchronize(CFSTR("com.sassoty.pulltorespring"));
    //In this case, you get the value for the key "enabled"
    //you could do the same thing for any other value, just cast it to id and use the conversion methods
    id enabledVal = (id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.sassoty.pulltorespring"));
    enabled = !enabledVal ? YES : [enabledVal boolValue];
    if (enabled) {
        NSLog(@"[PullToRespring] We are enabled");
        if(!prevEnabled)
            createRefreshControl();
    } else {
        NSLog(@"[PullToRespring] We are NOT enabled");
        if(refreshControl) [refreshControl removeFromSuperview];
    }
}

// iOS 8
%group Default
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
    NSLog(@"[PullToRespring] Respringing...");
    [refreshControl endRefreshing];
    system("killall backboardd");
}

%end
%end

// iOS 9

@interface PSUIPrefsListController : PSListController
- (UIRefreshControl *)initiateRefreshControl;
- (void)respringForDays;
@end

%group iOS9
%hook PSUIPrefsListController

- (id)init {
    listController = %orig;
    return listController;
}

- (void)viewDidAppear:(BOOL)view {
    %orig;
    createRefreshControl();
}

%new -(void)respringForDays {
    NSLog(@"[PullToRespring] Respringing...");
    [refreshControl endRefreshing];
    system("killall backboardd");
}

%end
%end

%ctor {
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                                    (CFNotificationCallback)loadPreferences,
                                    CFSTR("com.sassoty.pulltorespring/prefsChanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPreferences();

    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0"))
        %init(iOS9);
    else
        %init(Default);

}
