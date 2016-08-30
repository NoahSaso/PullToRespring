#import <Preferences/PSListController.h>
#import <notify.h>

@interface PSListController (PullToRespring)
- (id)table;
@end

@interface PrefsListController : PSListController
@end
@interface PSUIPrefsListController : PSListController
@end

@interface SpringBoard : UIApplication
- (void)_relaunchSpringBoardNow;
- (void)_tearDownNow;
@end

@interface FBSSystemService : NSObject
+ (id)sharedService;
- (void)sendActions:(id)arg1 withResult:(id)arg2;
@end

@interface SBSRestartRenderServerAction : NSObject
+ (id)restartActionWithTargetRelaunchURL:(id)arg1;
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

%group NonSB

// iOS 8 & 7
%hook PrefsListController
- (void)viewDidAppear:(BOOL)animated {
	%orig;
    [self.table addSubview: createRefreshControlWithListController(self)];
    loadPreferences();
}
%end // End of PrefsListController

// iOS 9 +
%hook PSUIPrefsListController
- (void)viewDidAppear:(BOOL)animated {
	%orig;
    [self.table addSubview: createRefreshControlWithListController(self)];
    loadPreferences();
}
%end // End of PSUIPrefsListController

%end // %group NonSB

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
	// iOS 8+
	if(%c(SBSRestartRenderServerAction) && %c(FBSSystemService)) {
		// Respring
		FBSSystemService *service = [%c(FBSSystemService) sharedService];
		[service sendActions:[NSSet setWithObject:[%c(SBSRestartRenderServerAction) restartActionWithTargetRelaunchURL:nil]] withResult:nil];
	// iOS 7-
	} else {
		// Respring
		notify_post("com.sassoty.pulltorespring.respring");
	}
}

- (void)updateRefreshControlExistence:(BOOL)shouldExist {
    if(shouldExist) {
        [self.listController.table addSubview: createRefreshControlWithListController(self.listController)];
    }else {
        if(self.refreshControl) {
            [self.refreshControl removeFromSuperview];
        }
    }
}

@end

static void respringSB() {
	SpringBoard *springBoard = (SpringBoard *)[UIApplication sharedApplication];
	if([springBoard respondsToSelector:@selector(_relaunchSpringBoardNow)]) {
		[springBoard _relaunchSpringBoardNow];
	}else if([springBoard respondsToSelector:@selector(_tearDownNow)]) {
		[springBoard _tearDownNow];
	}else {
		// This block shouldn't happen TO MY KNOWLEDGE on iOS 7+
		HBLogDebug(@"IF THIS IS CALLED, SOMETHING IS REALLLLLLLLLY WRONG");
	}
}

%ctor {
	if([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
				(CFNotificationCallback)respringSB,
				CFSTR("com.sassoty.pulltorespring.respring"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	}else {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
			(CFNotificationCallback)loadPreferences,
			CFSTR("com.sassoty.pulltorespring.prefschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		%init(NonSB);
	}
}
