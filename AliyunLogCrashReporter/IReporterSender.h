//
//  IReporterSender.h
//  AliyunLogCrashReporter
//
//  Created by gordon on 2021/5/19.
//

#import <Foundation/Foundation.h>
#import <AliyunLogCommon/AliyunLogCommon.h>

NS_ASSUME_NONNULL_BEGIN

@interface IReporterSender : NSObject
- (void) initWithSLSConfig: (SLSConfig *)config;
- (BOOL) sendDada: (TCData *)tcdata;
@end

NS_ASSUME_NONNULL_END
