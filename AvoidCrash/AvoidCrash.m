//
//  AvoidCrash.m
//  AvoidCrash
//
//  Created by mac on 16/9/21.
//  Copyright © 2016年 chenfanfang. All rights reserved.
//

#import "AvoidCrash.h"

//category
#import "NSArray+AvoidCrash.h"
#import "NSMutableArray+AvoidCrash.h"

#import "NSDictionary+AvoidCrash.h"
#import "NSMutableDictionary+AvoidCrash.h"

#import "NSString+AvoidCrash.h"
#import "NSMutableString+AvoidCrash.h"



#define AvoidCrashSeparator         @"================================================================"
#define AvoidCrashSeparatorWithFlag @"========================AvoidCrash Log=========================="

#define key_errorName        @"errorName"
#define key_errorReason      @"errorReason"
#define key_errorPlace       @"errorPlace"
#define key_defaultToDo      @"defaultToDo"
#define key_callStackSymbols @"callStackSymbols"
#define key_exception        @"exception"


@implementation AvoidCrash


+ (void)becomeEffective {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        [NSArray avoidCrashExchangeMethod];
        [NSMutableArray avoidCrashExchangeMethod];
        
        [NSDictionary avoidCrashExchangeMethod];
        [NSMutableDictionary avoidCrashExchangeMethod];
        
        [NSString avoidCrashExchangeMethod];
        [NSMutableString avoidCrashExchangeMethod];
        
    });
}

+ (void)exchangeClassMethod:(Class)anClass method1Sel:(SEL)method1Sel method2Sel:(SEL)method2Sel {
    Method method1 = class_getClassMethod(anClass, method1Sel);
    Method method2 = class_getClassMethod(anClass, method2Sel);
    method_exchangeImplementations(method1, method2);
}

+ (void)exchangeInstanceMethod:(Class)anClass method1Sel:(SEL)method1Sel method2Sel:(SEL)method2Sel {
    Method method1 = class_getInstanceMethod(anClass, method1Sel);
    Method method2 = class_getInstanceMethod(anClass, method2Sel);
    method_exchangeImplementations(method1, method2);
}



/**
 *  获取堆栈主要崩溃精简化的信息<根据正则表达式匹配出来>
 *
 *  @param callStackSymbolStr 堆栈主要崩溃信息
 *
 *  @return 堆栈主要崩溃精简化的信息
 */

+ (NSString *)getMainCallStackSymbolMessageWithCallStackSymbolStr:(NSString *)callStackSymbolStr {
    
    //mainCallStackSymbolMsg的格式为   +[类名 方法名]  或者 -[类名 方法名]
    __block NSString *mainCallStackSymbolMsg = nil;
    
    //匹配出来的格式为 +[类名 方法名]  或者 -[类名 方法名]
    NSString *regularExpStr = @"[-\\+]\\[.+\\]";
    
    NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:regularExpStr options:NSRegularExpressionCaseInsensitive error:nil];
    
    [regularExp enumerateMatchesInString:callStackSymbolStr options:NSMatchingReportProgress range:NSMakeRange(0, callStackSymbolStr.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        if (result) {
            mainCallStackSymbolMsg = [callStackSymbolStr substringWithRange:result.range];
            *stop = YES;
        }
    }];
    
    
    
    return mainCallStackSymbolMsg;
}


+ (void)noteErrorWithException:(NSException *)exception defaultToDo:(NSString *)defaultToDo {

    //堆栈数据
    NSArray *callStackSymbolsArr = [NSThread callStackSymbols];
    
    //获取在哪个类的哪个方法中实例化的数组  字符串格式 -[类名 方法名]  或者 +[类名 方法名]
    NSString *mainCallStackSymbolMsg = [AvoidCrash getMainCallStackSymbolMessageWithCallStackSymbolStr:callStackSymbolsArr[2]];
    
    if (mainCallStackSymbolMsg == nil) {
        
        mainCallStackSymbolMsg = @"崩溃方法定位失败,请您查看函数调用栈来排查错误原因";
        
    }
    
    NSString *errorName = exception.name;
    NSString *errorReason = exception.reason;
    //errorReason 可能为 -[__NSCFConstantString avoidCrashCharacterAtIndex:]: Range or index out of bounds
    //将avoidCrash去掉
    errorReason = [errorReason stringByReplacingOccurrencesOfString:@"avoidCrash" withString:@""];
    
    NSString *errorPlace = [NSString stringWithFormat:@"Error Place:%@",mainCallStackSymbolMsg];
    
    NSString *logErrorMessage = [NSString stringWithFormat:@"\n\n%@\n\n%@\n%@\n%@\n%@\n\n%@\n\n",AvoidCrashSeparatorWithFlag, errorName, errorReason, errorPlace, defaultToDo, AvoidCrashSeparator];
    NSLog(@"%@", logErrorMessage);
    
    NSDictionary *errorInfoDic = @{
                                   key_errorName        : errorName,
                                   key_errorReason      : errorReason,
                                   key_errorPlace       : errorPlace,
                                   key_defaultToDo      : defaultToDo,
                                   key_exception        : exception,
                                   key_callStackSymbols : callStackSymbolsArr
                                   };
    
    //将错误信息放在字典里，用通知的形式发送出去
    [[NSNotificationCenter defaultCenter] postNotificationName:AvoidCrashNotification object:nil userInfo:errorInfoDic];
}


@end
