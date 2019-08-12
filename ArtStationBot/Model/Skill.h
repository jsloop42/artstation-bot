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
/** The message associated with the skill. */
@property (nonatomic, readwrite) NSString *message;
@property (nonatomic, readwrite) NSString *originalMessage;  /* The current message is copied to originalMessage until it's persisted, which is used in editing.  */
@end

NS_ASSUME_NONNULL_END
