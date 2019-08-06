//
//  Software.h
//  ArtStationBot
//
//  Created by jsloop on 30/07/19.
//

#import <Foundation/Foundation.h>
#import "CrawlerState.h"

NS_ASSUME_NONNULL_BEGIN

@interface Software : NSObject
@property (nonatomic, readwrite) NSUInteger softwareId;
@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *iconURL;
@end

NS_ASSUME_NONNULL_END
