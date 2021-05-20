//
//  IFileParser.m
//  AliyunLogCrashReporter
//
//  Created by gordon on 2021/5/19.
//

#import "IFileParser.h"

@implementation IFileParser
- (void) parseFileWithType: (NSString *) type andFilePath: (NSString *) filePath{
    NSLog(@"subclass must implement parseFileWithType: method");
}
@end
