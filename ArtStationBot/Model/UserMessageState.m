//
//  UserMessageState.m
//  ArtStationBot
//
//  Created by jsloop on 10/08/19.
//

#import "UserMessageState.h"

@implementation UserMessageKey

- (BOOL)isEqual:(id)other {
    if ([[other classForCoder] isNotEqualTo:[self classForCoder]]) return NO;
    UserMessageKey *key = (UserMessageKey *)other;
    return self.skillId == key.skillId && self.userId == key.userId;
}

- (NSUInteger)hash {
    return [self.skillId integerValue] + [self.userId integerValue];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    UserMessageKey *key = [UserMessageKey new];
    key.skillId = self.skillId;
    key.userId = self.userId;
    return key;
}

@end

@implementation UserMessageState

- (instancetype)init {
    self = [super init];
    if (self) {
        [self bootstrap];
    }
    return self;
}

- (void)bootstrap {
    self.isMessaged = NO;
}

- (BOOL)isEqual:(id)other {
    if ([[other classForCoder] isNotEqualTo:[self classForCoder]]) return NO;
    UserMessageState *state = (UserMessageState *)other;
    return self.skill.skillId == state.skill.skillId && self.user.userId == state.user.userId;
}

- (NSUInteger)hash {
    return self.user.userId + self.skill.skillId;
}

@end
