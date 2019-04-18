




//
//  FTPManager.m
//  huaHongStaff
//
//  Created by 小马 on 16/10/28.
//  Copyright © 2016年 基石信息. All rights reserved.
//

#import "FTPManager.h"
#import "FileManager.h"
@implementation FTPManager

- (void)createFTPRequest:(NSData *)data url:(NSString *)url{
    self.imageNameStr = [NSString stringWithFormat:@"%@.png",[Common stringWithUUID]];
    [FileManager creatFile:[FileManager getDocumentsDirectory] Data:data Name:self.imageNameStr];
    self.filePath = [[NSString alloc]initWithFormat:@"%@/%@",[FileManager getDocumentsDirectory],self.imageNameStr];
    if ([FileManager fileSizeAtPath:self.filePath]>0) {
        [self filedPath:self.filePath url:[NSURL URLWithString:url]];
    }
}
/*
 filedPath 图片路径
 url       ftp服务器的地址
 */
- (void)filedPath:(NSString *)filedPath url:(NSURL *)url{
    CFWriteStreamRef ftpStream;
    //添加后缀（文件名称）
    url = (__bridge NSURL *)(CFURLCreateCopyAppendingPathComponent(NULL, (CFURLRef) url, (CFStringRef) [filedPath lastPathComponent], false));
    
    //读取文件，转化为输入流
    
    self.fileStream = [NSInputStream inputStreamWithFileAtPath:filedPath];
    [self.fileStream open];
    
    //为url开启CFFTPStream输出流
    ftpStream = CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url);
    self.networkStream = (__bridge NSOutputStream *) ftpStream;
    
    //设置ftp账号密码
    [self.networkStream setProperty:FTPUserName forKey:(id)kCFStreamPropertyFTPUserName];
    [self.networkStream setProperty:FTPUserPassWord forKey:(id)kCFStreamPropertyFTPPassword];
    
    //设置networkStream流的代理，任何关于networkStream的事件发生都会调用代理方法
    self.networkStream.delegate = self;
    
    //设置runloop
    [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.networkStream open];
    
    //完成释放链接
    CFRelease(ftpStream);
}

#pragma mark 回调方法
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    uint8_t buffer[32768];
    //aStream 即为设置为代理的networkStream
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            //开启连接
            NSLog(@"NSStreamEventOpenCompleted");
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"NSStreamEventHasBytesAvailable");
            assert(NO);     // 在上传的时候不会调用
        } break;
        case NSStreamEventHasSpaceAvailable: {
            //正在传输
            NSLog(@"NSStreamEventHasSpaceAvailable");
            NSLog(@"bufferOffset is %zd",self.bufferOffset);
            NSLog(@"bufferLimit is %zu",self.bufferLimit);
            if (self.bufferOffset == self.bufferLimit) {
                NSInteger   bytesRead;
                bytesRead = [self.fileStream read:buffer maxLength:32768];
                
                if (bytesRead == -1) {
                    //读取文件错误
                    [self _stopSendWithStatus:@"读取文件错误"];
                } else if (bytesRead == 0) {
                    //文件读取完成 上传完成
                    [self _stopSendWithStatus:nil];
                } else {
                    self.bufferOffset = 0;
                    self.bufferLimit  = bytesRead;
                }
            }
            
            if (self.bufferOffset != self.bufferLimit) {
                //写入数据
                NSInteger bytesWritten;//bytesWritten为成功写入的数据
                bytesWritten = [self.networkStream write:&buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    [self _stopSendWithStatus:@"网络写入错误"];
                } else {
                    self.bufferOffset += bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
            [self _stopSendWithStatus:@"Stream打开错误"];
//            assert(NO);
        } break;
        case NSStreamEventEndEncountered: {
            // 忽略
        } break;
        default: {
            assert(NO);
        } break;
    }
}

//结果处理
- (void)_stopSendWithStatus:(NSString *)statusString
{
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    [self _sendDidStopWithStatus:statusString];
}

- (void)_sendDidStopWithStatus:(NSString *)statusString
{
//    if (statusString == nil) {
//        statusString = @"上传成功";
//        NSLog(@"上传成功");
//    }else{
//        NSLog(@"上传不成功");
//    }
    if ([_delegate respondsToSelector:@selector(FTPManagerSendDidStopWithStatus:imageName:)]) {
        [_delegate FTPManagerSendDidStopWithStatus:statusString imageName:self.filePath];
    }
}
@end
