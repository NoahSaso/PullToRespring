@interface PrefsListController : UIViewController
@end

%hook PrefsListController

- (void)viewDidAppear:(BOOL)view {
	%orig;
	UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
	[refreshControl addTarget:self action:@selector(respringForDays) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:refreshControl];
}

%new - (void)respringForDays {
	system("killall -9 SpringBoard");
}

%end
