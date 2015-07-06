#import "ViewController.h"
#import "GCDAsyncUdpSocket.h"
#import "DDLog.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface ViewController ()
{
	long tag;
	GCDAsyncUdpSocket *udpSocket;
	
	NSMutableString *log;
}

@end




@implementation ViewController



- (IBAction)initMgs:(id)sender {
    NSString *msg = messageField.text;
    msg=@"5580000000414141414141414141414141414141424242424242424242424242424242424242424242424242424242424242424242424242aa";
    
    Byte byte[] = {0x55,0x80,0x00};
    NSString *hexStr;
    
    NSLog(@"%hhu",byte[0]);
    for(int i=0;i<2;i++)
    {
   //NSString *a=[NSString stringWithFormat:@"%hhu",byte[i]];
    //    NSLog(a);
      //  hexStr=hexStr+a;
   //     hexStr=a;
        
    }

    
    
    
    
    
    
    
    messageField.text=hexStr;
    
    
    
    
    
}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		log = [[NSMutableString alloc] init];
	}
	return self;
}

- (void)setupSocket
{
	// Setup our socket.
	// The socket will invoke our delegate methods using the usual delegate paradigm.
	// However, it will invoke the delegate methods on a specified GCD delegate dispatch queue.
	// 
	// Now we can configure the delegate dispatch queues however we want.
	// We could simply use the main dispatc queue, so the delegate methods are invoked on the main thread.
	// Or we could use a dedicated dispatch queue, which could be helpful if we were doing a lot of processing.
	// 
	// The best approach for your application will depend upon convenience, requirements and performance.
	// 
	// For this simple example, we're just going to use the main thread.
	
	udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    
	 
    
	NSError *error = nil;
    [udpSocket enableBroadcast:YES error:&error];
	
	if (![udpSocket bindToPort:0 error:&error])
	{
		[self logError:FORMAT(@"Error binding: %@", error)];
		return;
	}
	if (![udpSocket beginReceiving:&error])
	{
		[self logError:FORMAT(@"Error receiving: %@", error)];
		return;
	}
	
	[self logInfo:@"Ready"];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (udpSocket == nil)
	{
		[self setupSocket];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(keyboardWillShow:)
	                                             name:UIKeyboardWillShowNotification 
	                                           object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(keyboardWillHide:)
	                                             name:UIKeyboardWillHideNotification
	                                           object:nil];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)getKeyboardHeight:(float *)keyboardHeightPtr
        animationDuration:(double *)animationDurationPtr
                     from:(NSNotification *)notification
{
	float keyboardHeight;
	double animationDuration;
	
	// UIKeyboardCenterBeginUserInfoKey:
	// The key for an NSValue object containing a CGRect
	// that identifies the start frame of the keyboard in screen coordinates.
	
	CGRect beginRect = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect endRect   = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
	{
		keyboardHeight = ABS(beginRect.origin.x - endRect.origin.x);
	}
	else
	{
		keyboardHeight = ABS(beginRect.origin.y - endRect.origin.y);
	}
	
	// UIKeyboardAnimationDurationUserInfoKey
	// The key for an NSValue object containing a double that identifies the duration of the animation in seconds.
	
	animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	
	if (keyboardHeightPtr) *keyboardHeightPtr = keyboardHeight;
	if (animationDurationPtr) *animationDurationPtr = animationDuration;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	float keyboardHeight = 0.0F;
	double animationDuration = 0.0;
	
	[self getKeyboardHeight:&keyboardHeight animationDuration:&animationDuration from:notification];
	
	CGRect webViewFrame = webView.frame;
	webViewFrame.size.height -= keyboardHeight;
	
	void (^animationBlock)(void) = ^{
		
		webView.frame = webViewFrame;
	};
	
	UIViewAnimationOptions options = 0;
	
	[UIView animateWithDuration:animationDuration
	                      delay:0.0
	                    options:options
	                 animations:animationBlock
	                 completion:NULL];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	float keyboardHeight = 0.0F;
	double animationDuration = 0.0;
	
	[self getKeyboardHeight:&keyboardHeight animationDuration:&animationDuration from:notification];
	
	CGRect webViewFrame = webView.frame;
	webViewFrame.size.height += keyboardHeight;
	
	void (^animationBlock)(void) = ^{
		
		webView.frame = webViewFrame;
	};
	
	UIViewAnimationOptions options = 0;
	
	[UIView animateWithDuration:animationDuration
	                      delay:0.0
	                    options:options
	                 animations:animationBlock
	                 completion:NULL];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	DDLogError(@"webView:didFailLoadWithError: %@", error);
}

- (void)webViewDidFinishLoad:(UIWebView *)sender
{
	NSString *scrollToBottom = @"window.scrollTo(document.body.scrollWidth, document.body.scrollHeight);";
	
    [sender stringByEvaluatingJavaScriptFromString:scrollToBottom];
}

- (void)logError:(NSString *)msg
{
	NSString *prefix = @"<font color=\"#B40404\">";
	NSString *suffix = @"</font><br/>";
	
	[log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
	
	NSString *html = [NSString stringWithFormat:@"<html><body>\n%@\n</body></html>", log];
	[webView loadHTMLString:html baseURL:nil];
}

- (void)logInfo:(NSString *)msg
{
	NSString *prefix = @"<font color=\"#6A0888\">";
	NSString *suffix = @"</font><br/>";
	
	[log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
	
	NSString *html = [NSString stringWithFormat:@"<html><body>\n%@\n</body></html>", log];
	[webView loadHTMLString:html baseURL:nil];
}

- (void)logMessage:(NSString *)msg
{
	NSString *prefix = @"<font color=\"#000000\">";
	NSString *suffix = @"</font><br/>";
	
	[log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
	
	NSString *html = [NSString stringWithFormat:@"<html><body>%@</body></html>", log];
	[webView loadHTMLString:html baseURL:nil];
}


+ (NSString *)hexStringFromString:(NSString *)string{
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    } 
    return hexStr; 
}

- (IBAction)send:(id)sender
{
	NSString *host = addrField.text;
    
	if ([host length] == 0)
	{
		[self logError:@"Address required"];
		return;
	}
	
	int port = [portField.text intValue];
	if (port <= 0 || port > 65535)
	{
		[self logError:@"Valid port required"];
		return;
	}
  
	NSString *msg = messageField.text;
    Byte byte[] = {0x55,0x70,0x00,0x00,0x00,  0x01,0x08,0x06,0x06,0x03,0x07,0x03,0x05,0x05,0x02,0x08,0x00,0x00,0x00,0x00,   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,    0xAA};
    
   NSData *adata = [[NSData alloc] initWithBytes:byte length:57];

  //  msg=self.hexStringFromString (msg);
   // NSString *a=hexStringFromString(msg);
	if ([msg length] == 0)
	{
		[self logError:@"Message required"];
		return;
	}
	
	NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    
	[udpSocket sendData:adata toHost:host port:port withTimeout:-1 tag:tag];
   /* [udpSocket sendData:data
                    toHost:@"255.255.255.255"
                        port:9527
                 withTimeout:-1
                         tag:0];
    
	*/
	[self logMessage:FORMAT(@"SENTwo (%i): %@", (int)tag, msg)];
	
	tag++;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
	// You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
	// You could add checks here
}



- (void)initBrocast{
    
   
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                               fromAddress:(NSData *)address
                                         withFilterContext:(id)filterContext
{
	NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (msg)
	{
		[self logMessage:FORMAT(@"RECV: %@", msg)];
	}
	else
	{
		NSString *host = nil;
		uint16_t port = 0;
		[GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
		
		[self logInfo:FORMAT(@"RECV: Unknown message from: %@:%hu", host, port)];
	}
}

@end
