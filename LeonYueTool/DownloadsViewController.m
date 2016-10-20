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

static NSString *VideoCellIdentifier = @"VideoTableViewCell";

@interface DownloadsViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) NSMutableArray<NSString *> *videoFiles;

@end

@implementation DownloadsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSError *error = nil;
    NSLog(@"video path:%@",getVideoPath());
    self.videoFiles = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:getVideoPath() error:&error]];
    NSLog(@"videoFiles:%@",self.videoFiles);
    [self.tableview reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videoFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VideoCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = self.videoFiles[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AVPlayerViewController *controller = [[AVPlayerViewController alloc] init];
    controller.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:[getVideoPath() stringByAppendingPathComponent:self.videoFiles[indexPath.row]]]];
    [self presentViewController:controller animated:YES completion:^{
        [controller.player play];
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NSFileManager defaultManager] removeItemAtPath:[getVideoPath() stringByAppendingPathComponent:self.videoFiles[indexPath.row]] error:nil];
    [self.videoFiles removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}
- (IBAction)export:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        for (NSString *vF in self.videoFiles) {
            dispatch_group_enter(group);
            [self save:[getVideoPath() stringByAppendingPathComponent:vF] block:^{
                dispatch_group_leave(group);
            }];
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view makeToast:[NSString stringWithFormat:@"export progress:%ld/%ld",[self.videoFiles indexOfObject:vF],self.videoFiles.count] duration:4.f position:CSToastPositionTop];
            });
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view makeToast:@"export finished" duration:4.f position:CSToastPositionTop];
        });
        
        
    });


}

- (void)save:(NSString*)urlString block:(void(^)())complete{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:urlString]
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
