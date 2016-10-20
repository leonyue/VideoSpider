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

@interface ViewController ()<UIWebViewDelegate>
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
        NSLog(@"url:%@",request.URL);
        return NO;
    }
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

// 接收到服务器跳转请求之后调用
//- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
//// 在收到响应后，决定是否跳转
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;
//// 在发送请求之前，决定是否跳转
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;

@end
