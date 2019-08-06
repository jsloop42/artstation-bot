//
//  Skill.h
//  ArtStationBot
//
//  Created by jsloop on 30/07/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Skill : NSObject
@property (nonatomic, readwrite) NSUInteger skillId;
@property (nonatomic, readwrite) NSString *name;
@end

NS_ASSUME_NONNULL_END
