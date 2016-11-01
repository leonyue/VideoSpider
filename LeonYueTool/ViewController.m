//
//  ViewController.m
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 16/9/22.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoDownManager.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<UIWebViewDelegate,UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (strong, nonatomic) NSMutableArray *tmpDownloadingArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tmpDownloadingArray = [NSMutableArray new];
    self.webView.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemBecameCurrent:)
                                                 name:@"AVPlayerItemBecameCurrentNotification"
                                               object:nil];
    NSString *rawUrlStr = @"http://ningbocouples.tumblr.com/post/125911497332/这个棒棒我喜欢";
    rawUrlStr = @"http://m.toutiao.com/a6341692131777708545/?iid=5920552262&app=news_article";
    rawUrlStr = @"http://m.toutiao.com/a6344591133214556417/?iid=5920552262&app=news_article";
    rawUrlStr = @"";
    self.urlTextField.text = rawUrlStr;
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)backButtonClick:(id)sender {
    [self.webView goBack];
}
- (IBAction)goButtonClick:(id)sender {
    NSString *rawUrlStr = [self.urlTextField text];
    NSString *urlStr = [rawUrlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [self.webView loadRequest:
     [NSURLRequest requestWithURL:
      [NSURL URLWithString:urlStr
       ]
      ]
     ];
}
- (IBAction)pasteToGo:(id)sender {
    self.urlTextField.text = [UIPasteboard generalPasteboard].string;
    [self goButtonClick:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *rawUrlStr = [self.urlTextField text];
    NSString *urlStr = [rawUrlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [self.webView loadRequest:
     [NSURLRequest requestWithURL:
      [NSURL URLWithString:urlStr
       ]
      ]
     ];
    [textField resignFirstResponder];
    return YES;
}

- (void)playerItemBecameCurrent:(NSNotification*)notification
{
    AVPlayerItem *playerItem = [notification object];
    if(playerItem == nil) return;
    AVURLAsset *asset = (AVURLAsset*)[playerItem asset];
    NSURL *url = [asset URL]; // this is URL you need
    if ([url.absoluteString hasPrefix:@"file:///var/mobile"]) {///本地视频
        return;
    }
    __block BOOL alreadyDownloaded = NO;
    [self.tmpDownloadingArray enumerateObjectsUsingBlock:^(NSURL *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.absoluteString isEqualToString:url.absoluteString]) {
            alreadyDownloaded = YES;
            *stop = YES;
        }
    }];
    if (alreadyDownloaded) {
        return;
    }
    [[VideoDownManager sharedDownManager] startVideoDownloadingFromURL:url];
    [self.tmpDownloadingArray addObject:url];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *scheme = request.URL.scheme;
    if ([request.URL.absoluteString rangeOfString:@"scheme=http"].location == NSNotFound &&
        [request.URL.absoluteString rangeOfString:@"scheme="].location != NSNotFound) {
        return NO;
    }
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        return YES;
    }
    else {
        return NO;
    }
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

@end
