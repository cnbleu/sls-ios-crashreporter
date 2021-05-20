//
//  SLSCrashReporterPlugin.m
//  AliyunLogCrashReporter
//
//  Created by gordon on 2021/5/19.
//

#import "SLSCrashReporterPlugin.h"
#import "AliyunLogCrashReporter.h"
#import "SLSReporterSender.h"

@implementation SLSCrashReporterPlugin
IReporterSender *sender = nil;
IFileParser *fileParser = nil;

- (instancetype)init
{
    if (self = [super init]) {
        sender = [[SLSReporterSender alloc] init];
    }
    return self;
}

- (NSString *)name{
    return @"SLSCrashReporterPlugin";
}

- (BOOL) initWithSLSConfig: (SLSConfig *) config {
    [super initWithSLSConfig:config];
    [sender initWithSLSConfig:config];
    
    TCData *data = [TCData createDefaultWithSLSConfig:config];
    BOOL res = [sender sendDada:data];
    NSLog(@"send res: %lu", res);
    
    return YES;
}

@end
