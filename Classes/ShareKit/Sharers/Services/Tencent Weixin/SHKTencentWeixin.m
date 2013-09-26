#import "SHKTencentWeixin.h"
#import "SHKConfiguration.h"

@interface SHKTencentWeixin ()

- (NSData *)resizeWithImage:(UIImage*)image scale:(CGFloat)scale compression:(CGFloat)compression;

@end

static NSString *const kSHKTencentWeixinUserInfo = @"kSHKTencentWeixinUserInfo";

@implementation SHKTencentWeixin


+ (SHKTencentWeixin *)sharedInstance
{
    static SHKTencentWeixin *weixin = nil;
    @synchronized([SHKTencentWeixin class]) {
        if ( ! weixin)
        {
            weixin = [[SHKTencentWeixin alloc] init];
        }
    }
    
    return weixin;
}


#pragma mark - Handle Wx SDK Methods

+ (void)registerApp
{
    [WXApi registerApp:SHKCONFIG(tencentWeixinAppId)];
}

+ (BOOL)handleOpenURL:(NSURL*)url
{
    return [WXApi handleOpenURL:url delegate:[SHKTencentWeixin sharedInstance]];
}


#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"发送给微信好友";
}

+ (BOOL)canShareURL
{
	return ([WXApi isWXAppInstalled] && [WXApi isWXAppSupportApi]);
}

+ (BOOL)canShareText
{
	return ([WXApi isWXAppInstalled] && [WXApi isWXAppSupportApi]);
}

+ (BOOL)canShareImage
{
    return ([WXApi isWXAppInstalled] && [WXApi isWXAppSupportApi]);
}

+ (BOOL)canShareFile:(SHKFile *)file{
	return [file.filename rangeOfString:@".gif" options:NSCaseInsensitiveSearch].location != NSNotFound;
}

-(BOOL)quiet{
    return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return NO;
}

#pragma mark -
#pragma mark Authorization

+ (void)logout
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKTencentWeixinUserInfo];
	[super logout];
}

- (BOOL)isAuthorized
{
    return YES;
}

#pragma mark -
#pragma mark UI Implementation

- (void)show
{
    if (self.item.shareType == SHKShareTypeURL)
	{
		[self.item setCustomValue:[NSString stringWithFormat:@"%@: %@", self.item.title, [self.item.URL absoluteString]] forKey:@"status"];
        [self showTencentWeixinForm];
	}
    
    else if (self.item.shareType == SHKShareTypeText)
    {
        [self.item setCustomValue:[self.item text] forKey:@"status"];
        [self showTencentWeixinForm];
    }
    
	else if (self.item.shareType == SHKShareTypeImage)
	{
		[self send];
	}
}

- (void)showTencentWeixinForm
{
    SHKFormControllerLargeTextField *rootView = [[SHKFormControllerLargeTextField alloc] initWithNibName:nil bundle:nil delegate:self];
    
	rootView.text = [self.item customValueForKey:@"status"];
	rootView.maxTextLength = 140;
	rootView.image = self.item.image;
	rootView.imageTextLength = 25;
    
	self.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,self);
    
	[self pushViewController:rootView animated:NO];
	[rootView release];
    
	[[SHK currentHelper] showViewController:self];
}

- (void)sendForm:(SHKFormControllerLargeTextField *)form
{
    self.item.text = form.textView.text;
	[self tryToSend];
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

- (void)share{
	if (self.item.shareType != SHKShareTypeImage && self.item.shareType != SHKShareTypeFile && ! [self validateItemAfterUserEdit])
		return ;
    
    switch (self.item.shareType) {
            
        case SHKShareTypeURL:
        case SHKShareTypeText:
            [self sendStatus];
            break;
            
        case SHKShareTypeImage:
        case SHKShareTypeFile:
            [self sendImage];
            break;
		default:
			break;
	}
    
	// Notify delegate
	[self sendDidStart];
    
	return ;
}

- (void)sendStatus
{
    SendMessageToWXReq *req = [[[SendMessageToWXReq alloc] init] autorelease];
    [req setBText:YES];
    [req setText:[self.item customValueForKey:@"status"]];
    
    req.scene=[self myScene];
    [WXApi sendReq:req];
}

- (void)sendImage
{
    CGFloat compression = 0.9f;
    NSData *imageData = [self resizeWithImage:[self.item image] scale:compression compression:compression];
    
    // Webchat limit thumb image size is 32kb, so if the image is bigger than that, it will process
    // for resize and compression.
	while ([imageData length] > 32768 && compression > 0.1)
    {
		compression -= 0.1;
        imageData = [self resizeWithImage:[self.item image] scale:compression compression:compression];
	}
    
    UIImage *thumb = [UIImage imageWithData:imageData];
    
    WXMediaMessage *message=[WXMediaMessage message];
    [message setThumbImage:thumb];
    WXImageObject *ext=[WXImageObject object];
	if (self.item.file && [self.item.file.filename rangeOfString:@".gif" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		[ext setImageData:self.item.file.data];
	}else if(self.item.image){
		[ext setImageData:UIImagePNGRepresentation([self.item image])];
	}
    
    message.mediaObject=ext;
    
    SendMessageToWXReq* req=[[[SendMessageToWXReq alloc] init] autorelease];
    req.bText=NO;
    req.message=message;
    req.scene=[self myScene];
    
    [WXApi sendReq:req];
}

- (int)myScene{
	return WXSceneSession;
}

#pragma mark - Image process

- (NSData *)resizeWithImage:(UIImage*)image scale:(CGFloat)scale compression:(CGFloat)compression
{
    CGSize newSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
    
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return UIImageJPEGRepresentation(newImage, compression);
}


#pragma mark - Weixin delegate methods


- (void)onResp:(BaseResp *)resp
{
    switch ([resp errCode])
    {
        case WXSuccess:
            [self sendDidFinish];
            break;
        case WXErrCodeUserCancel:
            [self sendDidCancel];
            break;
        default:
            [self sendDidFailWithError:nil];
            break;
    }
}
@end
@implementation SHKTencentWeixinFriends

+ (NSString *)sharerTitle
{
	return @"发送到微信朋友圈";
}
- (int)myScene{
	return WXSceneTimeline;
}

@end