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
#import "SenderDetails.h"

NS_ASSUME_NONNULL_BEGIN

@interface StateData : NSObject
@property (atomic, readwrite) NSMutableArray<Country *> *countries;
@property (atomic, readwrite) NSMutableArray<Skill *> *skills;
@property (atomic, readwrite) NSMutableArray<Software *> *software;
@property (nonatomic, readwrite) BOOL isDarkMode;
@property (nonatomic, readwrite, nullable) SenderDetails *senderDetails;
+ (instancetype)shared;
- (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
