//
//  utility.m
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/20.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//


#import "utility.h"

NSString *randomFileName() {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss:SSS"];
    return [dateFormatter stringFromDate:[NSDate date]];
    
    return [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    
    NSMutableString *outputStr =[NSMutableString new];
    
    /// ABCDE-ABCDE-ABCDE-ABCDE   5 11 17
    for (int i = 0; i < 23; i++) {
        if (i == 5 || i == 11 || i == 17) {
            [outputStr appendString:@"-"];
        }else {
            [outputStr appendFormat:@"%c",(arc4random() % 26) + 65];
        }
    }
    
    return outputStr;
}

NSString *getDocumentPath() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

NSString *getVideoPath() {
    NSString *path = [getDocumentPath() stringByAppendingPathComponent:@"Videos"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}
