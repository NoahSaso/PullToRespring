#import <Preferences/Preferences.h>

@interface PullToRespringListController: PSListController {
}
@end

@implementation PullToRespringListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"PullToRespring" target:self] retain];
	}
	return _specifiers;
}
@end

// vim:ft=objc
