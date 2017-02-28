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

//@property (nonatomic,strong) NSMutableArray<NSURLSessionDownloadTask *>* downLoadTasks;
@property (nonatomic,strong) AFHTTPSessionManager *bgManager;
@property (nonatomic,strong) NSTimer *saveContextTimer;
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
//    self.downLoadTasks = [NSMutableArray new];
    self.saveContextTimer = [NSTimer timerWithTimeInterval:1.f repeats:YES block:^(NSTimer * _Nonnull timer) {
        [[VideoResourceCoreDataManager sharedManager] saveContext];
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - 暂停&&继续下载

- (void)resumeAllResource {
    for (VideoDownloadResource *resource  in self.videoResourceArray) {
        if (resource.video_status != VideoStatusDownloaded && resource.video_status != VideoStatusDownloading) {
            [self resumeResourceDownload:resource];
        }
    }
    [[VideoResourceCoreDataManager sharedManager] saveContext];
}

- (void)pauseAllResource {
    for (VideoDownloadResource *resource  in self.videoResourceArray) {
        if (resource.video_status == VideoStatusDownloading) {
            [self pauseResourceDownload:resource];
        }
    }
    [[VideoResourceCoreDataManager sharedManager] saveContext];
}

#pragma mark - 应用程序状态通知
- (void)applicationDidBecomeActive:(NSNotification *)notif {
    [self resumeAllResource];
}

- (void)applicationWillResignActive:(NSNotification *)notif {
    
}

- (void)applicationWillTerminate:(NSNotification *)notif {
    [self pauseAllResource];
}

- (VideoDownloadResource *)startVideoDownloadingFromURL:(NSURL *)url {
    AFHTTPSessionManager *manager = self.bgManager;
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    
    VideoDownloadResource *resource = [[VideoDownloadResource alloc] initWithUrl:url];
    if (resource == nil) {
        NSLog(@"already exists");
        return nil;
    }
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        resource.progress = downloadProgress.fractionCompleted;
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [resource getTempFileUrl];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [weakSelf finishDownloadingResource:resource :response :filePath :error];
    }];
    resource.linkedTask = task;
//    [self.downLoadTasks addObject:task];
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
    }
    deleteFile([resource getResumableFileUrl]);
    deleteFile([resource getTempFileUrl]);
    deleteFile([resource getTargetFileUrl]);
    
    resource.video_status = VideoStatusDeleted;
    [self removeFromDB:resource];
    [[VideoResourceCoreDataManager sharedManager] saveContext];
}

- (void)resumeResourceDownload:(VideoDownloadResource *)resource {
    NSData *data = [NSData dataWithContentsOfURL:[resource getResumableFileUrl]];
    __weak typeof(self) weakSelf = self;
    AFHTTPSessionManager *manager = self.bgManager;
    
    if (data != nil) {
        NSLog(@"%p ...->继续",resource);
        NSURLSessionDownloadTask *task = [manager downloadTaskWithResumeData:data progress:^(NSProgress * _Nonnull downloadProgress) {
            resource.progress = downloadProgress.fractionCompleted;
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [resource getTempFileUrl];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [weakSelf finishDownloadingResource:resource :response :filePath :error];
        }];
        resource.linkedTask = task;
        resource.video_status = VideoStatusDownloading;
//        [self.downLoadTasks addObject:task];
        [task resume];
    }
    else {
        NSLog(@"重新继续");
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:resource.video_url]];
        
        __weak typeof(self) weakSelf = self;
        NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            resource.progress = downloadProgress.fractionCompleted;
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [resource getTempFileUrl];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [weakSelf finishDownloadingResource:resource :response :filePath :error];
        }];
        resource.linkedTask = task;
        resource.video_status = VideoStatusDownloading;
//        [self.downLoadTasks addObject:task];
        [task resume];
    }
}


- (void)finishDownloadingResource:(VideoDownloadResource *)resource
                                 :(NSURLResponse * _Nonnull)response
                                 :(NSURL * _Nullable)filePath
                                 :(NSError * _Nullable)error {
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
            NSError *err = nil;
            BOOL success = [[NSFileManager defaultManager] moveItemAtURL:filePath toURL:[resource getTargetFileUrl] error:&err];
            if (success && err == nil) {
                resource.video_status = VideoStatusDownloaded;
            }
            else {
                resource.video_status = VideoStatusFailed;
                NSLog(@"Move file fail:%@",err.localizedDescription);
            }
        }
        else {
            resource.video_status = VideoStatusFailed;
            NSLog(@"No File");
        }
    }
    else {
        if (error.code == -999) {
            resource.video_status = VideoStatusPaused;
        }
        else {
            resource.video_status = VideoStatusFailed;
            NSLog(@"Download file fail:%@",error.localizedDescription);
        }
        
    }
    [[VideoResourceCoreDataManager sharedManager] saveContext];
}

- (NSArray *)videoResourceArray {
    if (nil == _videoResourceArray) {
        _videoResourceArray = [NSMutableArray arrayWithArray:[self getAllVideoResourcesExceptDeleted]];
    }
    return _videoResourceArray;
}

#pragma mark - lazy

- (AFHTTPSessionManager *)bgManager {
    if (_bgManager == nil) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.leony.tool.background_download"];
        config.discretionary = YES;
        _bgManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    }
    return _bgManager;
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
            [[VideoResourceCoreDataManager sharedManager] saveContext];
        }
    }
    
}

@end
