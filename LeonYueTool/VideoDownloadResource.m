//
//  VideoDownloadResource.m
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/20.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import "VideoDownloadResource.h"
#import "VideoResourceCoreDataManager.h"
#import "VideoResource+CoreDataProperties.h"

NSString *const LYNewResourceModifiedNotification = @"LYNewResourceModifiedNotification";

@implementation VideoDownloadResource

- (id)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        _video_url = url.absoluteString;
        _video_status = VideoStatusDownloading;
        _localFileName = randomFileName();
        _progress      = 0.f;
        _extension     = @"";
        if ([self alreadyExists]) {
            NSLog(@"already exists");
            return nil;
        }
        else {
            [self insertToDB];
        }
    }
    return self;
}

- (id)initWithUrl:(NSString *)url status:(VideoStatus)status fileName:(NSString *)fileName progress:(double)progress extension:(NSString *)extension {
    self = [super init];
    if (self) {
        _video_url = url;
        _video_status = status;
        _localFileName = fileName;
        _progress = progress;
        _extension = extension;
    }
    return self;
}

- (NSURL *)getResumableFileUrl {
    NSString *fileUrl = [getVideoPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.tmp",self.localFileName]];
    return [NSURL fileURLWithPath:fileUrl];
}

- (NSURL *)getTargetFileUrl {
    if ([self.extension isEqualToString:@""]) {
        return nil;
    }
    NSString *fileUrl = [getVideoPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",self.localFileName,self.extension]];
    return [NSURL fileURLWithPath:fileUrl];
}


#pragma mark - core data

- (BOOL)alreadyExists {
    NSFetchRequest *request = [VideoResource fetchRequest];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"video_url=%@",self.video_url];
    request.predicate = predicate;
    NSManagedObjectContext *context = [VideoResourceCoreDataManager sharedManager].managedObjectContext;
    NSError *error = nil;
    NSArray *result = [context executeFetchRequest:request error:&error];
    if (error == nil && result.count != 0) {
        return YES;
    }
    return NO;
}

- (void)insertToDB {
    
    NSManagedObjectContext *context = [VideoResourceCoreDataManager sharedManager].managedObjectContext;
    VideoResource *resource = [NSEntityDescription insertNewObjectForEntityForName:@"VideoResource" inManagedObjectContext:context];
    resource.video_url = self.video_url;
    resource.video_status = @(self.video_status);
    resource.localFileName = self.localFileName;
    resource.progress      = @(self.progress);
    resource.extension     = self.extension;
//    [[VideoResourceCoreDataManager sharedManager] saveContext];
}

- (void)updateToDB {
    NSFetchRequest *request = [VideoResource fetchRequest];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"video_url=%@",self.video_url];
    request.predicate = predicate;
    NSManagedObjectContext *context = [VideoResourceCoreDataManager sharedManager].managedObjectContext;
    NSError *error = nil;
    NSArray *result = [context executeFetchRequest:request error:&error];
    if (error == nil && result.count == 1) {
        VideoResource *resource = result[0];
        resource.video_url = self.video_url;
        resource.video_status = @(self.video_status);
        resource.localFileName = self.localFileName;
        resource.progress      = @(self.progress);
        resource.extension     = self.extension;
    }
//    [[VideoResourceCoreDataManager sharedManager] saveContext];
}

- (void)setVideo_url:(NSString *)video_url {
    if (![_video_url isEqualToString:video_url]) {
        _video_url = [video_url copy];
        [self updateToDB];
        [[NSNotificationCenter defaultCenter] postNotificationName:LYNewResourceModifiedNotification object:self];
    }
}

- (void)setLocalFileName:(NSString *)localFileName {
    if (![_localFileName isEqualToString:localFileName]) {
        _localFileName = [localFileName copy];
        [self updateToDB];
        [[NSNotificationCenter defaultCenter] postNotificationName:LYNewResourceModifiedNotification object:self];
    }
}

- (void)setExtension:(NSString *)extension {
    if (![_extension isEqualToString:extension]) {
        _extension = [extension copy];
        [self updateToDB];
        [[NSNotificationCenter defaultCenter] postNotificationName:LYNewResourceModifiedNotification object:self];
    }
}

- (void)setVideo_status:(VideoStatus)video_status {
    if (_video_status != video_status) {
        _video_status = video_status;
        [self updateToDB];
        if (video_status != VideoStatusDeleted) {
            [[NSNotificationCenter defaultCenter] postNotificationName:LYNewResourceModifiedNotification object:self];
        }
        
    }
}

- (void)setProgress:(double)progress {
    if (_progress != progress) {
        _progress = progress;
        [self updateToDB];
        [[NSNotificationCenter defaultCenter] postNotificationName:LYNewResourceModifiedNotification object:self];
    }
}

@end
