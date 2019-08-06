//
//  Filters.h
//  ArtStationBot
//
//  Created by jsloop on 03/08/19.
//

#import <Foundation/Foundation.h>
#import "Availability.h"
#import "Country.h"
#import "Skill.h"
#import "Software.h"

NS_ASSUME_NONNULL_BEGIN

@interface Filters : NSObject
@property (nonatomic, readwrite) NSMutableArray<Availability *> *availabilities;
@property (nonatomic, readwrite) NSMutableArray<Country *> *countries;
@property (nonatomic, readwrite) NSMutableArray<Skill *> *skills;
@property (nonatomic, readwrite) NSMutableArray<Software *> *software;
@end

NS_ASSUME_NONNULL_END
