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
#import "VideoResourceCoreDataManager.h"
#import "VideoResource+CoreDataProperties.h"


NSString *const LYNewResourceAddedNotification = @"LYNewResourceAddedNotification";
static VideoDownManager *_shareDownManager;

void deleteFile(NSURL * file){
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:file error:&error];
}

@interface VideoDownManager ()

@property (nonatomic,strong) NSMutableArray<NSURLSessionDownloadTask *>* downLoadTasks;
@end

@implementation VideoDownManager

+ (id)sharedDownManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareDownManager = [[self alloc] init];
        [_shareDownManager setUp];
    });
    return _shareDownManager;
}

- (void)setUp {
    self.downLoadTasks = [NSMutableArray new];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notif {
    for (VideoDownloadResource *resource  in self.videoResourceArray) {
        if (resource.video_status == VideoStatusPaused) {
            [self resumeResourceDownload:resource];
        }
    }
    
}

- (void)applicationWillResignActive:(NSNotification *)notif {
    for (VideoDownloadResource *resource  in self.videoResourceArray) {
        if (resource.video_status == VideoStatusDownloading) {
            [self pauseResourceDownload:resource];
        }
    }
    [[VideoResourceCoreDataManager sharedManager] saveContext];
    
}

- (void)applicationWillTerminate:(NSNotification *)notif {
    for (VideoDownloadResource *resource  in self.videoResourceArray) {
        if (resource.video_status == VideoStatusDownloading) {
            [self pauseResourceDownload:resource];
        }
    }
    [[VideoResourceCoreDataManager sharedManager] saveContext];
}

- (VideoDownloadResource *)startVideoDownloadingFromURL:(NSURL *)url {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    
    VideoDownloadResource *resource = [[VideoDownloadResource alloc] initWithUrl:url];
    if (resource == nil) {
        NSLog(@"already exists");
        return nil;
    }
    
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        resource.progress = downloadProgress.fractionCompleted;
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [resource getResumableFileUrl];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//        response.MIMEType
        if (resource.video_status == VideoStatusPaused) {
            return;
        }
        [self.downLoadTasks removeObject:task];
        
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
        
        resource.extension = extension;
        
        if (error == nil) {
            if (filePath != nil) {
                [[NSFileManager defaultManager] moveItemAtURL:filePath toURL:[resource getTargetFileUrl] error:nil];
                resource.video_status = VideoStatusDownloaded;
            }
            else {
                resource.video_status = VideoStatusFailed;
                NSLog(@"No File");
            }
            
        }
    }];
    resource.linkedTask = task;
    [self.downLoadTasks addObject:task];
    [task resume];
    [[NSNotificationCenter defaultCenter] postNotificationName:LYNewResourceAddedNotification object:self userInfo:@{@"resource":resource}];
    return resource;
}

- (void)pauseResourceDownload:(VideoDownloadResource *)resource {
    if (resource.linkedTask == nil) {
        resource.video_status = VideoStatusPaused;
        return;
    }
    [resource.linkedTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        [resumeData writeToURL:[resource getResumableFileUrl] atomically:YES];
        NSLog(@"resouce:%p 暂停下载",resource);
        resource.video_status = VideoStatusPaused;
        
    }];
}

- (void)deleteResource:(VideoDownloadResource *)resource {
    if (resource.video_status == VideoStatusDownloading) {
        [resource.linkedTask cancel];
        [self removeFromDB:resource];
    }
    else if (resource.video_status == VideoStatusFailed) {
        [self removeFromDB:resource];
    }
    else if (resource.video_status == VideoStatusPaused) {
        deleteFile([resource getResumableFileUrl]);
        [self removeFromDB:resource];
    }
    else if (resource.video_status == VideoStatusDownloaded) {
        deleteFile([resource getTargetFileUrl]);
        resource.video_status = VideoStatusDeleted;
    }
    else if (resource.video_status == VideoStatusDeleted) {
    }
}

- (void)resumeResourceDownload:(VideoDownloadResource *)resource {
    if (resource.video_status == VideoStatusPaused) {
        NSLog(@"%p 暂停->继续",resource);
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSData *data = [NSData dataWithContentsOfURL:[resource getResumableFileUrl]];
        if (data == nil) {
            resource.video_status = VideoStatusFailed;
            return;
        }
        deleteFile([resource getResumableFileUrl]);
        NSURLSessionDownloadTask *task = [manager downloadTaskWithResumeData:data progress:^(NSProgress * _Nonnull downloadProgress) {
            resource.progress = downloadProgress.fractionCompleted;
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [resource getResumableFileUrl];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            //        response.MIMEType
            if (resource.video_status == VideoStatusPaused) {
                return;
            }
            [self.downLoadTasks removeObject:task];
            
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
            
            resource.extension = extension;
            
            if (error == nil) {
                if (filePath != nil) {
                    [[NSFileManager defaultManager] moveItemAtURL:filePath toURL:[resource getTargetFileUrl] error:nil];
                    resource.video_status = VideoStatusDownloaded;
                }
                else {
                    resource.video_status = VideoStatusFailed;
                    NSLog(@"No File");
                }
                
            }
            else {
                resource.video_status = VideoStatusFailed;
                NSLog(@"downoad fail");
            }
        }];
        resource.linkedTask = task;
        resource.video_status = VideoStatusDownloading;
        [self.downLoadTasks addObject:task];
        [task resume];
    }
    else if (resource.video_status == VideoStatusFailed || resource.video_status == VideoStatusDeleted || resource.video_status == VideoStatusDownloading){
        NSLog(@"失败->继续");
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:resource.video_url]];
        
        NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            resource.progress = downloadProgress.fractionCompleted;
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [resource getResumableFileUrl];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            //        response.MIMEType
            if (resource.video_status == VideoStatusPaused) {
                return;
            }
            [self.downLoadTasks removeObject:task];
            
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
            
            resource.extension = extension;
            
            if (error == nil) {
                if (filePath != nil) {
                    [[NSFileManager defaultManager] moveItemAtURL:filePath toURL:[resource getTargetFileUrl] error:nil];
                    resource.video_status = VideoStatusDownloaded;
                }
                else {
                    resource.video_status = VideoStatusFailed;
                    NSLog(@"No File");
                }
                
            }
        }];
        resource.linkedTask = task;
        resource.video_status = VideoStatusDownloading;
        [self.downLoadTasks addObject:task];
        [task resume];
    }
}


- (NSArray *)videoResourceArray {
    if (nil == _videoResourceArray) {
        _videoResourceArray = [NSMutableArray arrayWithArray:[self getAllVideoResourcesExceptDeleted]];
    }
    return _videoResourceArray;
}

#pragma mark - core data

- (NSArray *)getAllVideoResourcesExceptDeleted {
    NSFetchRequest *request = [VideoResource fetchRequest];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"video_status!=%ld",VideoStatusDeleted];
    request.predicate = predicate;
    NSManagedObjectContext *context = [VideoResourceCoreDataManager sharedManager].managedObjectContext;
    NSError *error = nil;
    NSArray *result = [context executeFetchRequest:request error:&error];
    
    NSMutableArray *mu = [NSMutableArray new];
    if (error == nil) {
        for (VideoResource *resource in result) {
            [mu addObject:[[VideoDownloadResource alloc] initWithUrl:resource.video_url status:[resource.video_status integerValue] fileName:resource.localFileName progress:[resource.progress doubleValue] extension:resource.extension]];
        }
    }
    return mu;
}

- (void)removeFromDB:(VideoDownloadResource *)resource {
    NSFetchRequest *request = [VideoResource fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"video_url=%@",resource.video_url];
    NSManagedObjectContext *context = [VideoResourceCoreDataManager sharedManager].managedObjectContext;
    NSError *error = nil;
    NSArray *result = [context executeFetchRequest:request error:&error];
    if (error == nil) {
        if (result.count != 0) {
            for (VideoResource *res in result) {
                [context deleteObject:res];
            }
//            [[VideoResourceCoreDataManager sharedManager] saveContext];
        }
    }
    
}

@end
