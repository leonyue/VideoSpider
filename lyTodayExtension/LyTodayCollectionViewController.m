//
//  LyTodayCollectionViewController.m
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 16/9/22.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import "LyTodayCollectionViewController.h"

@interface LyTodayCollectionViewController ()

@end

@implementation LyTodayCollectionViewController


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 5;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = indexPath.row > 4 ? @"collectionCell4" : [NSString stringWithFormat:@"collectionCell%ld",indexPath.row];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    // Configure the cell
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:@"http.*?$" options:NSRegularExpressionCaseInsensitive error:nil];
        NSString *stringInPasteboard = [UIPasteboard generalPasteboard].string;
        NSTextCheckingResult * result = [regular firstMatchInString:stringInPasteboard options:0 range:NSMakeRange(0, stringInPasteboard.length)];
        if (result.range.location != NSNotFound) {
            NSString *url = [stringInPasteboard substringWithRange:result.range];
            [UIPasteboard generalPasteboard].string = url;
            [self.extensionContext openURL:[NSURL URLWithString:url] completionHandler:^(BOOL success) {
                
            }];
        }
    }
    if (indexPath.row == 1) {
        [self.extensionContext openURL:[NSURL URLWithString:@"leonyueTool://"] completionHandler:^(BOOL success) {
            
        }];
    }
    
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
