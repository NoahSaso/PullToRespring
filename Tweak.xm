#import <Preferences/Preferences.h>
@interface PrefsListController : PSListController
@end

%hook PrefsListController

- (void)viewDidAppear:(BOOL)view {
	%orig;
	UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
	[refreshControl addTarget:self action:@selector(respringForDays) forControlEvents:UIControlEventValueChanged];
	[self.table addSubview:refreshControl];
	[refreshControl release];
}

%new - (void)respringForDays {
	system("killall -9 SpringBoard");
}

%end
