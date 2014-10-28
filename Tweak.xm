#import <Preferences/Preferences.h>
@interface PrefsListController : PSListController
- (UIRefreshControl *)initiateRefreshControl;
@end

static UIRefreshControl* refreshControl = nil;

%hook PrefsListController

- (void)viewDidAppear:(BOOL)view {
	%orig;
	if(refreshControl) [refreshControl removeFromSuperview];
	refreshControl = [self initiateRefreshControl];
	[self.table addSubview:refreshControl];
}

%new - (UIRefreshControl *)initiateRefreshControl {
	if(!refreshControl) {
		refreshControl = [[UIRefreshControl alloc] init];
		[refreshControl addTarget:self action:@selector(respringForDays) forControlEvents:UIControlEventValueChanged];
	}
	return refreshControl;
}

%new - (void)respringForDays {
	system("killall -9 SpringBoard");
}

%end
