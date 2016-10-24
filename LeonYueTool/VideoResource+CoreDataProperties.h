//
//  VideoResource+CoreDataProperties.h
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/20.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import "VideoResource+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface VideoResource (CoreDataProperties)

+ (NSFetchRequest<VideoResource *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *video_url;
@property (nonatomic) NSNumber *video_status;
@property (nullable, nonatomic, copy) NSString *localFileName;
@property (nonatomic) NSNumber *progress;
@property (nullable, nonatomic, copy) NSString *extension;

@end

NS_ASSUME_NONNULL_END
