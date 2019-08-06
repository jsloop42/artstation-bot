//
//  StateData.h
//  ArtStationBot
//
//  Created by jsloop on 04/08/19.
//

#import <Foundation/Foundation.h>
#import "Country.h"
#import "SampleProject.h"
#import "Skill.h"
#import "Software.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface StateData : NSObject
@property (atomic, readwrite) NSMutableArray<Country *> *countries;
@property (atomic, readwrite) NSMutableArray<Skill *> *skills;
@property (atomic, readwrite) NSMutableArray<Software *> *software;
+ (instancetype)shared;
- (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
