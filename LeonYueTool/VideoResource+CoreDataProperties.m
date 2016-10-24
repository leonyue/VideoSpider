//
//  VideoResource+CoreDataProperties.m
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/20.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import "VideoResource+CoreDataProperties.h"

@implementation VideoResource (CoreDataProperties)

+ (NSFetchRequest<VideoResource *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"VideoResource"];
}

@dynamic video_url;
@dynamic video_status;
@dynamic localFileName;
@dynamic progress;
@dynamic extension;

@end
