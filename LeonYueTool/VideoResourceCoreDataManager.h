//
//  VideoResourceCoreDataManager.h
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/20.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoResourceCoreDataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (VideoResourceCoreDataManager *)sharedManager;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
