//
//  CrawlerState.h
//  ArtStationBot
//
//  Created by jsloop on 05/08/19.
//

#import <Foundation/Foundation.h>
#import "UserFetchState.h"

NS_ASSUME_NONNULL_BEGIN

@interface CrawlerState : NSObject
@property (atomic, readwrite) NSMutableDictionary<NSNumber *, UserFetchState *> *fetchState;  // <skillId, userFetchState>
@end

NS_ASSUME_NONNULL_END
