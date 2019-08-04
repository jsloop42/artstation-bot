//
//  Constants.h
//  ArtStationBot
//
//  Created by jsloop on 01/08/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define NSLog(FORMAT, ...) fprintf(stderr, "%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#ifdef DEBUG
#   define debug(...) NSLog(__VA_ARGS__)
#   define info(...) NSLog(__VA_ARGS__)
#   define error(...) NSLog(__VA_ARGS__)
#else
#   define info(...) NSLog(__VA_ARGS__)
#   define error(...) NSLog(__VA_ARGS__)
#endif

@interface Constants : NSObject
+ (NSString *)seedURL;
+ (NSString *)csrfTokenURL;
+ (NSString *)contentTypeJSON;
+ (NSString *)domain;
+ (NSString *)filterListFragment;
+ (NSString *)filterListURL;
@end

NS_ASSUME_NONNULL_END