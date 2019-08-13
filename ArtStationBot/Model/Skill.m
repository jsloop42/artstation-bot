//
//  Skill.m
//  ArtStationBot
//
//  Created by jsloop on 30/07/19.
//

#import "Skill.h"

@implementation Skill

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    Skill *skill = [Skill new];
    skill.skillId = self.skillId;
    skill.name = self.name;
    skill.message = self.message;
    skill.originalMessage = self.originalMessage;
    skill.interpolatedMessage = self.interpolatedMessage;
    return skill;
}

@end
