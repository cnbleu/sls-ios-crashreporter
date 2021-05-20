//
//  IFileParser.h
//  AliyunLogCrashReporter
//
//  Created by gordon on 2021/5/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IFileParser : NSObject
- (void) parseFileWithType: (NSString *) type andFilePath: (NSString *) filePath;
@end

NS_ASSUME_NONNULL_END
