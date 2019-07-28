//
//  FoundationDBService.h
//  ArtStationBot
//
//  Created by jsloop on 23/07/19.
//

#import <Foundation/Foundation.h>
#define FDB_API_VERSION 610
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
#import "fdb_c.h"
#pragma clang diagnostic pop


NS_ASSUME_NONNULL_BEGIN

@interface FoundationDBService : NSObject
@property (nonatomic, readwrite) NSString *configPath;
@property (nonatomic, readwrite) FDBDatabase *db;
- (void)initDB;
@end

NS_ASSUME_NONNULL_END


