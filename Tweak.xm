#import <Preferences/Preferences.h>
@interface PrefsListController : PSListController
-(UIRefreshControl *)initiateRefreshControl;
+(id)sharedInstance;
-(id)table;
@end

static UIRefreshControl* refreshControl = nil;
static BOOL enabled = YES;

static PrefsListController* prefs;

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
        if(!prevEnabled) {
            refreshControl = [[%c(PrefsListController) sharedInstance] initiateRefreshControl];
            [[[%c(PrefsListController) sharedInstance] table] addSubview:refreshControl];
        }
    } else {
        NSLog(@"[PullToRespring] We are NOT enabled");
        if(refreshControl) [refreshControl removeFromSuperview];
    }
}

%hook PrefsListController

-(id)init {
    prefs = %orig;
    return prefs;
}

%new +(id)sharedInstance {
    return prefs;
}

-(void)viewDidAppear:(BOOL)view {
	%orig;
    if(refreshControl) [refreshControl removeFromSuperview];
    if(enabled) {
        refreshControl = [self initiateRefreshControl];
        [self.table addSubview:refreshControl];
    }
}

%new -(UIRefreshControl *)initiateRefreshControl {
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
