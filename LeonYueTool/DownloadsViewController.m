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

@interface DownloadsViewController ()<UITableViewDelegate,UITableViewDataSource,AVPlayerViewControllerDelegate,UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableview;

@end

@implementation DownloadsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceAdded:) name:LYNewResourceAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceModified:) name:LYNewResourceModifiedNotification object:nil];
    [[VideoDownManager sharedDownManager] resumeAllResource];
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
    NSArray *array = [VideoDownManager sharedDownManager].videoResourceArray;
    NSInteger row = [array indexOfObject:resource];
    NSArray *visibleIndexs = self.tableview.indexPathsForVisibleRows;
    if (row == NSNotFound) {
        return;
    }
    [visibleIndexs enumerateObjectsUsingBlock:^(NSIndexPath *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.row == row) {
            VideoTableViewCell *cell = [self.tableview cellForRowAtIndexPath:obj];
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.textLabel.text = resource.localFileName;
                cell.progress = resource.progress;
                switch (resource.video_status) {
                    case VideoStatusDownloading:
//                        cell.backgroundColor = [UIColor whiteColor];
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"progress:%.3f",resource.progress];
                        break;
                    case VideoStatusDownloaded:
//                        cell.backgroundColor = [UIColor greenColor];
                        cell.detailTextLabel.text = @"";
                        break;
                    case VideoStatusPaused:
//                        cell.backgroundColor = [UIColor yellowColor];
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"progress:%.3f",resource.progress];
                        break;
                    case VideoStatusFailed:
//                        cell.backgroundColor = [UIColor redColor];
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"download failed"];
                        break;
                    case VideoStatusDeleted:
//                        cell.backgroundColor = [UIColor redColor];
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"resource deleted"];
                        break;
                    default:
                        break;
                }
            });

            *stop = YES;
        }
        
    }];
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
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = resource.localFileName;
    cell.progress = resource.progress;
    switch (resource.video_status) {
        case VideoStatusDownloading:
//            cell.backgroundColor = [UIColor whiteColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"progress:%.3f",resource.progress];
            break;
        case VideoStatusDownloaded:
//            cell.backgroundColor = [UIColor greenColor];
            cell.detailTextLabel.text = @"";
            break;
        case VideoStatusPaused:
//            cell.backgroundColor = [UIColor yellowColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"progress:%.3f",resource.progress];
            break;
        case VideoStatusFailed:
//            cell.backgroundColor = [UIColor redColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"download failed"];
            break;
        case VideoStatusDeleted:
//            cell.backgroundColor = [UIColor redColor];
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
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"停止下载？" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *yesAction = nil;
        {
            UIAlertAction *actionYes = [UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[VideoDownManager sharedDownManager] pauseResourceDownload:resource];
            }];
            yesAction = actionYes;
        }
        [alert addAction:yesAction];
        
        UIAlertAction *noAction = nil;
        {
            UIAlertAction *actionNo = [UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }];
            noAction = actionNo;
        }
        [alert addAction:noAction];
        [self presentViewController:alert animated:YES completion:^{
            
        }];
        
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

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *action1 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        NSLog(@"删除");
        VideoDownloadResource *resource = [VideoDownManager sharedDownManager].videoResourceArray[indexPath.row];
        [[VideoDownManager sharedDownManager] deleteResource:resource];
        [[VideoDownManager sharedDownManager].videoResourceArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }];
    
    UITableViewRowAction *action2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"导出" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        NSLog(@"导出");
        VideoDownloadResource *resource = [VideoDownManager sharedDownManager].videoResourceArray[indexPath.row];
        [self save:[resource getTargetFileUrl] block:^{
            [self.tableview reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }];
    action2.backgroundColor = [UIColor blueColor];
    UITableViewRowAction *action3 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"重命名" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        NSLog(@"重命名");
        [self renameIndexPath:indexPath];
    }];
    action3.backgroundColor = [UIColor blackColor];
    return @[action1,action2,action3];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoDownloadResource *resource = [VideoDownManager sharedDownManager].videoResourceArray[indexPath.row];
    [[VideoDownManager sharedDownManager] deleteResource:resource];
    [[VideoDownManager sharedDownManager].videoResourceArray removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}
- (IBAction)deleteAll:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        for (VideoDownloadResource *resource in [VideoDownManager sharedDownManager].videoResourceArray) {
            [[VideoDownManager sharedDownManager] deleteResource:resource];
            [[VideoDownManager sharedDownManager].videoResourceArray removeObject:resource];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:getVideoPath() error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableview reloadData];
        });
        
        
    });
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

- (void)renameIndexPath:(NSIndexPath *)indexPath {
    VideoDownloadResource *resource = [VideoDownManager sharedDownManager].videoResourceArray[indexPath.row];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textfield = alert.textFields[0];
        NSString *text = textfield.text;
        resource.localFileName = text;
        [self.tableview reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.tableview reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = resource.localFileName;
        textField.delegate = self;
    }];
    [self presentViewController:alert animated:YES completion:^{
        
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UITextPosition *endDocument = textField.endOfDocument;
    UITextPosition *start = textField.beginningOfDocument;
    textField.selectedTextRange = [textField textRangeFromPosition:start toPosition:endDocument];
}

@end
