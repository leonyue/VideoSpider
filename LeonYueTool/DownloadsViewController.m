//
//  DownloadsViewController.m
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/20.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import "DownloadsViewController.h"
#import "VideoTableViewCell.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "VideoDownManager.h"
static NSString *VideoCellIdentifier = @"VideoTableViewCell";

@interface DownloadsViewController ()<UITableViewDelegate,UITableViewDataSource,AVPlayerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableview;

@end

@implementation DownloadsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceAdded:) name:LYNewResourceAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceModified:) name:LYNewResourceModifiedNotification object:nil];
    // Do any additional setup after loading the view.
}

- (void)resourceAdded:(NSNotification *)notif {
    VideoDownloadResource *resource = notif.userInfo[@"resource"];
    [[VideoDownManager sharedDownManager].videoResourceArray addObject:resource];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableview reloadData];
    });
    
}

- (void)resourceModified:(NSNotification *)notif {
    VideoDownloadResource *resource = notif.object;
    NSInteger row = [[VideoDownManager sharedDownManager].videoResourceArray indexOfObject:resource];
    if (row != NSNotFound) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableview reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
        
        
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [VideoDownManager sharedDownManager].videoResourceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VideoCellIdentifier forIndexPath:indexPath];
    VideoDownloadResource *resource = [VideoDownManager sharedDownManager].videoResourceArray[indexPath.row];
    if ([cell.textLabel.text isEqualToString:resource.localFileName]) {
        
    }
    else {
        cell.textLabel.text = resource.localFileName;
    }
    
    switch (resource.video_status) {
        case VideoStatusDownloading:
            cell.backgroundColor = [UIColor whiteColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"progress:%.3f",resource.progress];
            break;
        case VideoStatusDownloaded:
            cell.backgroundColor = [UIColor greenColor];
            cell.detailTextLabel.text = @"";
            break;
        case VideoStatusPaused:
            cell.backgroundColor = [UIColor yellowColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"progress:%.3f",resource.progress];
            break;
        case VideoStatusFailed:
            cell.backgroundColor = [UIColor redColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"download failed"];
            break;
        case VideoStatusDeleted:
            cell.backgroundColor = [UIColor redColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"resource deleted"];
            break;
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoDownloadResource *resource = [VideoDownManager sharedDownManager].videoResourceArray[indexPath.row];
    if (resource.video_status == VideoStatusDownloaded) {
        NSURL *url = [resource getTargetFileUrl];
        AVPlayerViewController *controller = [[AVPlayerViewController alloc] init];
        controller.player = [[AVPlayer alloc] initWithURL:url];
        controller.delegate = self;
        [self presentViewController:controller animated:YES completion:^{
            [controller.player play];
        }];
    }
    else if (resource.video_status == VideoStatusDownloading) {
        [[VideoDownManager sharedDownManager] pauseResourceDownload:resource];
    }
    else if (resource.video_status == VideoStatusPaused) {
        [[VideoDownManager sharedDownManager] resumeResourceDownload:resource];
    }
    else if (resource.video_status == VideoStatusFailed) {
        [[VideoDownManager sharedDownManager] resumeResourceDownload:resource];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoDownloadResource *resource = [VideoDownManager sharedDownManager].videoResourceArray[indexPath.row];
    [[VideoDownManager sharedDownManager] deleteResource:resource];
    [[VideoDownManager sharedDownManager].videoResourceArray removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}
- (IBAction)export:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        for (VideoDownloadResource *resource in [VideoDownManager sharedDownManager].videoResourceArray) {
            
            if (resource.video_status == VideoStatusDownloaded) {
                dispatch_group_enter(group);
                [self save:[resource getTargetFileUrl] block:^{
                    dispatch_group_leave(group);
                }];
                dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.view makeToast:[NSString stringWithFormat:@"export progress:%ld/%ld",[[VideoDownManager sharedDownManager].videoResourceArray indexOfObject:resource],[VideoDownManager sharedDownManager].videoResourceArray.count] duration:4.f position:CSToastPositionTop];
                });
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view makeToast:@"export finished" duration:4.f position:CSToastPositionTop];
        });
        
        
    });


}

- (void)save:(NSURL*)url block:(void(^)())complete{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:url
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    if (error) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self.view makeToast:[NSString stringWithFormat:@"export fail:%@",error] duration:1.f position:CSToastPositionTop];
                                        });
                                        
                                        NSLog(@"Save video fail:%@",error);
                                    } else {
                                        NSLog(@"Save video succeed.");
                                    }
                                    complete();
                                }];
}

@end
