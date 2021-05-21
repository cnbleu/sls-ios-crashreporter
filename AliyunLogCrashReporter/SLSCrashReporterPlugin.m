//
//  SLSCrashReporterPlugin.m
//  AliyunLogCrashReporter
//
//  Created by gordon on 2021/5/19.
//

#import "SLSCrashReporterPlugin.h"
#import "AliyunLogCrashReporter.h"
#import "UCTraceFileParser.h"
#import "SLSReporterSender.h"
#import "WPKMobi/WPKSetup.h"


typedef void(^content_changed_block)(NSString*);

@interface SLSCrashReporterPlugin ()

@property(nonatomic, strong) IReporterSender *sender;
@property(nonatomic, strong) IFileParser *fileParser;

@property(nonatomic, strong) dispatch_source_t crashLogSource;
@property(nonatomic, strong) dispatch_source_t crashStatLogSource;

- (void) initWPKMobi: (SLSConfig *)config;
- (void) startLogDirectoryMonitor;
- (void) stopLogDirectoryMonitor;

@end

@implementation SLSCrashReporterPlugin

void monitorDirectory(SLSCrashReporterPlugin* plugin, dispatch_source_t _source, NSString *path, content_changed_block hander) {
    NSURL *dirURL = [NSURL URLWithString:path];
    int const fd = open([[dirURL path]fileSystemRepresentation], O_EVTONLY);
    if (fd < 0) {
        NSLog(@"unable to open the path: %@", [dirURL path]);
    }
    
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE, DISPATCH_TARGET_QUEUE_DEFAULT);
    dispatch_source_set_event_handler(source, ^() {
        unsigned long const type = dispatch_source_get_data(source);
        switch (type) {
            case DISPATCH_VNODE_WRITE: {
                NSLog(@"directory changed. %@", path);
                hander(path);
                break;
            }
            default:
                break;
        }
    });
    
    dispatch_source_set_cancel_handler(source, ^{
        close(fd);
    });
    
    _source = source;
    dispatch_resume(_source);
}

- (instancetype)init
{
    if (self = [super init]) {
        self.sender = [[SLSReporterSender alloc] init];
        self.fileParser = [[UCTraceFileParser alloc] init];
    }
    return self;
}

- (NSString *)name{
    return @"SLSCrashReporterPlugin";
}

- (BOOL) initWithSLSConfig: (SLSConfig *) config {
    [super initWithSLSConfig:config];
    [self.sender initWithSLSConfig:config];
    [self.fileParser initWithSender:self.sender andSLSConfig:config];
    
    [self initWPKMobi:config];
    return YES;
}

#pragma mark - WPKMobi log directory monitor

- (void) initWPKMobi: (SLSConfig *) config {
    [self startLogDirectoryMonitor];
    
    [WPKSetup setIsEncryptLog:NO];
    [WPKSetup enableDebugLog:config.debuggable];
    [WPKSetup setCrashWritenCallback:^NSString * _Nullable(const char * _Nonnull crashUUID, WPKCrashType crashType, NSException * _Nullable exception) {
        NSLog(@"creashType: %zd, exception: ", crashType);
        return @"test";
    }];
//    [WPKSetup disableWPKReporter];
    [WPKSetup startWithAppName:config.pluginAppId];
    [WPKSetup sendAllReports];
    NSLog(@"initWPKMobi success.");
}

- (void) startLogDirectoryMonitor {
    // AppData/Library/.WPKLog/CrashLog
    // AppData/Library/.WPKLog/CrashStatLog
    NSString *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"libraryPath: %@", libraryPath);
    
    NSString *wpkLogpath = [libraryPath stringByAppendingPathComponent:@".WPKLog"];
    NSLog(@"wpkLogpath: %@", wpkLogpath);
    
    NSString *crashLogPath = [wpkLogpath stringByAppendingPathComponent:@"CrashLog"];
    NSLog(@"crashLogPath: %@", crashLogPath);
    
    NSString *crashStatLogPath = [wpkLogpath stringByAppendingPathComponent:@"CrashStatLog"];
    NSLog(@"CrashStatLogPath: %@", crashStatLogPath);
    
    monitorDirectory(self, self.crashLogSource, crashLogPath, ^(NSString *path) {
        [self.fileParser parseFileWithType:@"crash" andFilePath:path];
    });
    
    monitorDirectory(self, self.crashStatLogSource, crashStatLogPath, ^(NSString *path) {
        [self.fileParser parseFileWithType:@"crash_stat" andFilePath:path];
    });
    
//    [self.fileParser parseFileWithType:@"test" andFilePath:crashLogPath];
//    [self startMonitorFolder:crashLogPath];
}

- (void) startMonitorFolder:(NSString *)path {
    NSURL *dirURL = [NSURL URLWithString:path];
    int const fd = open([[dirURL path]fileSystemRepresentation], O_EVTONLY);
    if (fd < 0) {
        NSLog(@"unable to open the path: %@", [dirURL path]);
    }
    
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE, DISPATCH_TARGET_QUEUE_DEFAULT);
    dispatch_source_set_event_handler(source, ^() {
        unsigned long const type = dispatch_source_get_data(source);
        switch (type) {
            case DISPATCH_VNODE_WRITE: {
                NSLog(@"directory changed. %@", path);
                [self.fileParser parseFileWithType:@"crash" andFilePath:path];
                break;
            }
            default:
                break;
        }
    });
    
    dispatch_source_set_cancel_handler(source, ^{
        close(fd);
    });
    
    self.crashLogSource = source;
    dispatch_resume(self.crashLogSource);
}

- (void) stopLogDirectoryMonitor {
    dispatch_cancel(self.crashLogSource);
    dispatch_cancel(self.crashStatLogSource);
}


@end
