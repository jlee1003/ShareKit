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
-(void)dealloc{
    [super dealloc];
}
-(id)init{
    self = [super init];
    if (self) {
#ifdef _SHKDebugShowLogs
        
        [WeiboSDK enableDebugMode:YES];
#endif
        [WeiboSDK registerApp:SHKCONFIG(sinaWeiboConsumerKey)];
    }
    return self;
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

//+ (BOOL)canShareFile:(SHKFile *)file{
//	return [file.filename rangeOfString:@".gif" options:NSCaseInsensitiveSearch].location != NSNotFound;
//}

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
	return YES;
}

- (void)promptAuthorization
{
}

+ (void)logout
{
    
}

#pragma mark -
#pragma mark UI Implementation

- (void)show
{
    [self _sendToWeibo];
}

#pragma mark -
#pragma mark Share API Methods

-(void)_sendToWeibo{
    WBMessageObject *message = [WBMessageObject message];
    
    if (self.item.text){
        message.text = self.item.text;
    }
	if (self.item.file) {
		if ([self.item.file.filename rangeOfString:@".gif" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			// gif
			
			WBImageObject *image = [WBImageObject object];
			image.imageData = self.item.file.data;
			
			message.imageObject = image;
			if (!message.text) {
				message.text = self.item.title;
			}
		}else{
			NSAssert(false, @"file not supported");
		}
	}
    if (self.item.image) {
        WBImageObject *image = [WBImageObject object];
        image.imageData = UIImagePNGRepresentation(self.item.image);
        
        message.imageObject = image;
        if (!message.text) {
            message.text = self.item.title;
        }
    }
    if (self.item.URL) {
        WBWebpageObject *webpage = [WBWebpageObject object];
        webpage.objectID = self.item.URL.absoluteString;
        if (self.item.title)
            webpage.title = self.item.title;
        else
            webpage.title = self.item.URL.absoluteString;
        
        webpage.webpageUrl = self.item.URL.absoluteString;
        message.mediaObject = webpage;
    }
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message];
    
    [WeiboSDK sendRequest:request];
    
}

@end
