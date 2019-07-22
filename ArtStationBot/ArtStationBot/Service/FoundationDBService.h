//
//  FoundationDBService.h
//  ArtStationBot
//
//  Created by jsloop on 23/07/19.
//  Copyright © 2019 DreamLisp. All rights reserved.
//

#import <Foundation/Foundation.h>
#define FDB_API_VERSION 610
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
#import "fdb_c.h"
#pragma clang diagnostic pop


NS_ASSUME_NONNULL_BEGIN

@interface FoundationDBService : NSObject

@end

NS_ASSUME_NONNULL_END


