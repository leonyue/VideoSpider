//
//  GlobalDefine.h
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 16/9/22.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#ifndef GlobalDefine_h
#define GlobalDefine_h

#ifdef DEBUG
#define DNSLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DNSLog(format, ...)
#endif

#endif /* GlobalDefine_h */
