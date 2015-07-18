#import "ASCommon.h"
#include "time.h"
#include "stdlib.h"

static dispatch_queue_t TGLogQueue()
{
    static dispatch_queue_t queue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = dispatch_queue_create("com.telegraphkit.logging", 0);
    });
    return queue;
}

static NSFileHandle *TGLogFileHandle()
{
    static NSFileHandle *fileHandle = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *currentFilePath = [documentsDirectory stringByAppendingPathComponent:@"application-0.log"];
        NSString *oldestFilePath = [documentsDirectory stringByAppendingPathComponent:@"application-30.log"];
        
        if ([fileManager fileExistsAtPath:oldestFilePath])
            [fileManager removeItemAtPath:oldestFilePath error:nil];
        
        for (int i = 30 - 1; i >= 0; i--)
        {
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"application-%d.log", i]];
            NSString *nextFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"application-%d.log", i + 1]];
            if ([fileManager fileExistsAtPath:filePath])
            {
                [fileManager moveItemAtPath:filePath toPath:nextFilePath error:nil];
            }
        }
        
        [fileManager createFileAtPath:currentFilePath contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:currentFilePath];
        [fileHandle truncateFileAtOffset:0];
    });
    
    return fileHandle;
}

void TGLogSynchronize()
{
    dispatch_async(TGLogQueue(), ^
    {
        [TGLogFileHandle() synchronizeFile];
    });
}

void TGLogToFile(NSString *format, ...)
{
    va_list L;
    va_start(L, format);
    TGLogToFilev(format, L);
    va_end(L);
}

void TGLogToFilev(NSString *format, va_list args)
{
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];

    NSLog(@"TGLogToFilev: %@", message);
}

NSArray *TGGetLogFilePaths()
{
    NSMutableArray *filePaths = [[NSMutableArray alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    for (int i = 0; i <= 4; i++)
    {
        NSString *fileName = [NSString stringWithFormat:@"application-%d.log", i];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            [filePaths addObject:filePath];
        }
    }
    
    return filePaths;
}

NSArray *TGGetPackedLogs()
{
    NSMutableArray *resultFiles = [[NSMutableArray alloc] init];
    
    dispatch_sync(TGLogQueue(), ^
    {
        [TGLogFileHandle() synchronizeFile];
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        for (int i = 0; i <= 4; i++)
        {
            NSString *fileName = [NSString stringWithFormat:@"application-%d.log", i];
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            if ([fileManager fileExistsAtPath:filePath])
            {
                NSData *fileData = [[NSData alloc] initWithContentsOfFile:filePath];
                if (fileData != nil)
                    [resultFiles addObject:fileData];
            }
        }
    });
    
    return resultFiles;
}

