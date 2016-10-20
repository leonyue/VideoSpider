//
//  VideoDownManager.h
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/19.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoDownManager : NSObject

+ (id)sharedDownManager;

- (void)startVideoDownloadingFromURL:(NSURL *)url;

@end
