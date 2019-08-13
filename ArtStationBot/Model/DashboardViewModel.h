//
//  DashboardViewModel.h
//  ArtStationBot
//
//  Created by jsloop on 12/08/19.
//

#import <Foundation/Foundation.h>
#import "Skill.h"
#import "User.h"
#import "ASTableViewBuilder.h"

NS_ASSUME_NONNULL_BEGIN

@interface DashboardViewModel : NSObject
@property (nonatomic, readwrite) Skill *skill;
@property (nonatomic, readwrite) NSUInteger page;
@property (nonatomic, readwrite) NSDate *scheduledDate;
@property (nonatomic, readwrite) User *user;
@property (nonatomic, readwrite) enum ASTableView tableViewType;
@end

NS_ASSUME_NONNULL_END
