//
//  SHKSinaWeiboOAuth2.m
//  ShareKit
//
//  Created by icyleaf on 11-11-15.
//  Copyright (c) 2011 icyleaf.com. All rights reserved.
//

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKSinaWeibo.h"
#import "SHKConfiguration.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

@implementation SHKSinaWeibo
@synthesize weibo,hub;


static SHKSinaWeibo *sharedWeiboOauth2 = nil;

+ (SHKSinaWeibo *)sharedSHKSinaWeiboOAuth2
{
    if ( ! sharedWeiboOauth2)
    {
        sharedWeiboOauth2 = [[SHKSinaWeibo alloc] init];
    }
    
    return sharedWeiboOauth2;
}

-(void)dealloc{
    self.weibo = nil;
    [super dealloc];
}
-(oneway void)release{}
- (id)init
{
    if (!sharedWeiboOauth2) {
        self = [super init];
        if (self)
        {
            self.weibo = [[[WBEngine alloc] initWithAppKey:SHKCONFIG(sinaWeiboConsumerKey) appSecret:SHKCONFIG(sinaWeiboConsumerSecret)] autorelease];
            [self.weibo setRootViewController:self];
            [self.weibo setDelegate:self];
            [self.weibo setRedirectURI:SHKCONFIG(sinaWeiboCallbackUrl)];
            [self.weibo setIsUserExclusive:NO];
            //[self.weibo logOut];
        }
        sharedWeiboOauth2 = [self retain];
        return self;
    }
    [super release];
    return sharedWeiboOauth2;
}


#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
    return SHKLocalizedString(@"Sina Weibo");
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)canShareImage
{
	return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return NO;
}


#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized
{
	return [weibo isLoggedIn] && ![weibo isAuthorizeExpired];
}

- (void)promptAuthorization
{
    [weibo logIn];
}

+ (void)logout
{
    [[self sharedSHKSinaWeiboOAuth2].weibo logOut] ;
}

#pragma mark -
#pragma mark UI Implementation

- (void)show
{
    if (self.item.shareType == SHKShareTypeURL)
	{
        [self.item setCustomValue:[self.item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                      forKey:@"status"];
        
		[self showWeiboForm];
	}
    
    else if (self.item.shareType == SHKShareTypeImage)
	{
		[self showWeiboPublishPhotoDialog];
	}
	
	else if (self.item.shareType == SHKShareTypeText)
	{
        [self.item setCustomValue:self.item.text forKey:@"status"];
		[self showWeiboForm];
	}
}

- (void)showWeiboForm
{
    
    WBSendView *sendView = [[WBSendView alloc] initWithAppKey:SHKCONFIG(sinaWeiboConsumerKey) appSecret:SHKCONFIG(sinaWeiboConsumerSecret) text:[self.item customValueForKey:@"status"] image:nil];
    [sendView setDelegate:self];
    
    [sendView show:YES];
    [sendView release];
    
    
}

- (void)showWeiboPublishPhotoDialog
{
    WBSendView *sendView = [[WBSendView alloc] initWithAppKey:SHKCONFIG(sinaWeiboConsumerKey) appSecret:SHKCONFIG(sinaWeiboConsumerSecret) text:self.item.title image:self.item.image];
    [sendView setDelegate:self];
    
    [sendView show:YES];
    [sendView release];
}


#pragma mark -
#pragma mark Share API Methods

- (BOOL)validateItem
{
	if (self.item.shareType == SHKShareTypeUserInfo) {
		return YES;
	}
	
	NSString *status = [self.item customValueForKey:@"status"];
	return status != nil;
}

- (BOOL)validateItemAfterUserEdit
{
	BOOL result = NO;
	
	BOOL isValid = [self validateItem];
	NSString *status = [self.item customValueForKey:@"status"];
	
	if (isValid && status.length <= 140) {
		result = YES;
	}
	
    return result;
}

- (BOOL)send
{
    
	if ( ! [self validateItemAfterUserEdit]){
        return NO;
    }
    
    
	
	else
	{
        // TODO
	}
	
    
    
	return NO;
}

- (void)sendViewDidFinishSending:(WBSendView *)view
{
    NSLog(@"SUCCESS!!!");
    //self.hub.removeFromSuperViewOnHide = YES;
    //[self.hub hide:YES];
    [view hide:YES];
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil
													   message:@"微博发送成功！"
													  delegate:nil
											 cancelButtonTitle:@"确定"
											 otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (void)sendView:(WBSendView *)view didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    [view hide:YES];
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil
													   message:@"微博发送失败！"
													  delegate:nil
											 cancelButtonTitle:@"确定"
											 otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}
#pragma mark - WEEngineDelegate methods
- (void)engineAlreadyLoggedIn:(WBEngine *)engine{
    
    [self show];
}

- (void)engineDidLogIn:(WBEngine *)engine{
    [self show];
}

- (void)engine:(WBEngine *)engine didFailToLogInWithError:(NSError *)error{
    
	[self sendDidFailWithError:error];
}

- (void)engineDidLogOut:(WBEngine *)engine{
    
}
- (void)engine:(WBEngine *)engine requestDidFailWithError:(NSError *)error{
    [self sendDidFailWithError:[SHK error:SHKLocalizedString([error localizedDescription])]];
}
- (void)engine:(WBEngine *)engine requestDidSucceedWithResult:(id)result{
    
    [self sendDidFinish];
}

@end
