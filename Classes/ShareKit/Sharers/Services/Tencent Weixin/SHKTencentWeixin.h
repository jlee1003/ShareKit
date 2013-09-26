
#import <Foundation/Foundation.h>
#import "SHKOAuthSharer.h"
#import "SHKCustomFormControllerLargeTextField.h"
#import "WXApi.h"


@interface SHKTencentWeixin : SHKOAuthSharer <SHKFormControllerLargeTextFieldDelegate, WXApiDelegate>

#pragma mark - Handle WX SDK Methods

+ (void)registerApp;
+ (BOOL)handleOpenURL:(NSURL*)url;


#pragma mark - UI Implementation

- (void)showTencentWeixinForm;


#pragma mark - Share API Methods

- (void)sendStatus;
- (void)sendImage;
- (int)myScene;
@end
@interface SHKTencentWeixinFriends : SHKTencentWeixin
@end