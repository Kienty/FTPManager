//
//  FTPManager.h
//  huaHongStaff
//
//  Created by 小马 on 16/10/28.
//  Copyright © 2016年 基石信息. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FTPManagerDelegate <NSObject>

- (void)FTPManagerSendDidStopWithStatus:(NSString *)statusString imageName:(NSString *)photoName;

@end

@interface FTPManager : NSObject<NSStreamDelegate>

/*
 下边的属性不做过多的介绍。
 imageNameStr   图片的名字  通过GUID生成
 filePath       文件在本地的路径
 思路：因为从相册或相机中获取不到图片的路径，只能先讲图片的data获取到后保存到本地后，通过路径上传。
 
 代码使用了#import "FileManager.h" 进行了文件操作
 */
@property (nonatomic, assign) id <FTPManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL              isSending;
@property (nonatomic, retain)   NSOutputStream *  networkStream;
@property (nonatomic, retain)   NSInputStream *   fileStream;
//@property (nonatomic, readonly) uint8_t *         buffer;
@property (nonatomic, assign)   size_t            bufferOffset;
@property (nonatomic, assign)   size_t            bufferLimit;
@property (nonatomic,copy) NSString *imageNameStr;
@property (nonatomic,copy) NSString *filePath;
- (void)createFTPRequest:(NSData *)data url:(NSString *)url;

@end
