//
//  VideoDownManager.m
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/19.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import "VideoDownManager.h"
#import <AFNetworking/AFNetworking.h>
#import <UIView+Toast.h>

static VideoDownManager *_shareDownManager;

@implementation VideoDownManager

+ (id)sharedDownManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareDownManager = [[self alloc] init];
    });
    return _shareDownManager;
}

- (NSString *)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (void)startVideoDownloadingFromURL:(NSURL *)url {
    [[UIApplication sharedApplication].keyWindow makeToast:[NSString stringWithFormat:@"start downloading"] duration:2.f position:CSToastPositionBottom];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *fullPath = [[self getDocumentPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.tmp",[url.absoluteString stringByDeletingPathExtension].lastPathComponent]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"progress:%f",downloadProgress.fractionCompleted);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:fullPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//        response.MIMEType
        NSString *extension = @"Unknown";
        NSString *mime = [[response MIMEType] lowercaseString];
        if ([mime isEqualToString:@"application/octet-stream"]) {
            extension = @"flv";
        }
        else if ([mime isEqualToString:@"application/octet-stream"]) {
            extension = @"f4v";
        }
        else if ([mime isEqualToString:@"video/mp4"]) {
            extension = @"mp4";
        }
        else if ([mime isEqualToString:@"video/ogg"]) {
            extension = @"ogv";
        }
        else if ([mime isEqualToString:@"video/webm"]) {
            extension = @"webm";
        }
        else if ([mime isEqualToString:@"application/x-mpegurl"]) {
            extension = @"M3U8";
        }
        else if ([mime isEqualToString:@"application/vnd.apple.mpegurl"]) {
            extension = @"M3U8";
        }
        else if ([mime isEqualToString:@"video/mp2t"]) {
            extension = @"ts";
        }
        
        if ([extension isEqualToString:@"Unknown"]) {
            [[UIApplication sharedApplication].keyWindow makeToast:[NSString stringWithFormat:@"unknown file format with MIME:%@",mime] duration:2.f position:CSToastPositionBottom];
        }
        
        NSURL *targetUrl = [[filePath URLByDeletingPathExtension] URLByAppendingPathExtension:extension];
        [[NSFileManager defaultManager] moveItemAtURL:filePath toURL:targetUrl error:nil];
        
        if (error == nil) {
            NSLog(@"success download");
            [[UIApplication sharedApplication].keyWindow makeToast:[NSString stringWithFormat:@"Download success:%@",[targetUrl lastPathComponent]] duration:2.f position:CSToastPositionBottom];
        }
        else {
            NSLog(@"downoad fail");
        }
    }];
    [task resume];
}

@end
