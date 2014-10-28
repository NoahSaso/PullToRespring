#import <Preferences/Preferences.h>
@interface PrefsListController : PSListController
- (UIRefreshControl *)initiateRefreshControl;
@end

static UIRefreshControl* refreshControl = nil;
static BOOL enabled;

static void loadPreferences() {
    CFPreferencesAppSynchronize(CFSTR("com.sassoty.pulltorespring"));
    //In this case, you get the value for the key "enabled"
    //you could do the same thing for any other value, just cast it to id and use the conversion methods
    enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.sassoty.pulltorespring")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.sassoty.pulltorespring")) boolValue];
    if (enabled) {
        NSLog(@"[PullToRespring] We are enabled");
    } else {
        NSLog(@"[PullToRespring] We are NOT enabled");
        if(refreshControl) [refreshControl removeFromSuperview];
    }
}

%hook PrefsListController

- (void)viewDidAppear:(BOOL)view {
	%orig;
    if(refreshControl) [refreshControl removeFromSuperview];
    if(enabled) {
        refreshControl = [self initiateRefreshControl];
        [self.table addSubview:refreshControl];
    }
}

%new - (UIRefreshControl *)initiateRefreshControl {
    if(!refreshControl) {
        refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(respringForDays) forControlEvents:UIControlEventValueChanged];
    }
    return refreshControl;
}

%new - (void)respringForDays {
    NSLog(@"[PullToRespring] Respringing...");
    [refreshControl endRefreshing];
    system("killall backboardd");
}

%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)loadPreferences,
                                    CFSTR("com.sassoty.pulltorespring/prefsChanged"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPreferences();
}