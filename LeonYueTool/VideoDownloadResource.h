//
//  VideoDownloadResource.h
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/20.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSUInteger, VideoStatus) {
    VideoStatusDownloading,
    VideoStatusDownloaded,
    VideoStatusPaused,
    VideoStatusFailed,
    VideoStatusDeleted,
};


extern NSString *const LYNewResourceModifiedNotification;

@interface VideoDownloadResource : NSObject


- (id)initWithUrl:(NSURL *)url;
- (id)initWithUrl:(NSString *)url status:(VideoStatus)status fileName:(NSString *)fileName progress:(double)progress extension:(NSString *)extension;
@property (nonatomic, copy) NSString *video_url;
@property (nonatomic) VideoStatus video_status;
@property (nonatomic, copy) NSString *localFileName;
@property (nonatomic) double progress;
@property (nonatomic, copy) NSString *extension;



@property (nonatomic, weak) NSURLSessionDownloadTask *linkedTask;

- (NSURL *)getResumableFileUrl;

/**
 <#Description#>

 @return nil if not downloaded
 */
- (NSURL *)getTargetFileUrl;

@end
