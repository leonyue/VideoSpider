//
//  VideoDownManager.h
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/19.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoDownloadResource.h"


extern NSString *const LYNewResourceAddedNotification;

@interface VideoDownManager : NSObject

+ (VideoDownManager *)sharedDownManager;


@property (nonatomic, strong) NSMutableArray *videoResourceArray;

- (VideoDownloadResource *)startVideoDownloadingFromURL:(NSURL *)url;
- (void)pauseResourceDownload:(VideoDownloadResource *)resource;
- (void)resumeResourceDownload:(VideoDownloadResource *)resource;
- (void)deleteResource:(VideoDownloadResource *)resource;

@end
