//
//  ArtStationBotTests.m
//  ArtStationBotTests
//
//  Created by jsloop on 10/08/19.
//

#import <XCTest/XCTest.h>
#import "MessageTemplateRenderer.h"

@interface ArtStationBotTests : XCTestCase

@end

@implementation ArtStationBotTests {
    MessageTemplateRenderer *renderer;
}

- (void)setUp {
     renderer = [MessageTemplateRenderer new];
}

- (void)tearDown {
}

- (void)testTemplateRender {
    NSString *template = @"Hi ${user.fullName},\nWe have gone through your profile and found you to be awesome at ${skill.name}. So we would like to talk more if you are interested. Also your <a href='${user.profileURL}'>portfolio</a> is awesome.\nBest,\n${sender.name}\n${sender.email} | ${sender.url}";
    NSString *rendered = @"Hi Jane Doe,\nWe have gone through your profile and found you to be awesome at 2D Animation. So we would like to talk more if you are interested. Also your <a href='https://example.com'>portfolio</a> is awesome.\nBest,\nAlice\nsender@example.com | https://example.com";
    MessageTemplateField *field = [MessageTemplateField new];
    field.fullNameOfUser = @"Jane Doe";
    field.usernameOfUser = @"janedoe";
    field.profileURLOfUser = @"https://example.com";
    field.emailOfUser = @"jane.doe@example.com";
    field.skillName = @"2D Animation";
    field.nameOfSender = @"Alice";
    field.urlOfSender = @"https://example.com";
    field.emailOfSender = @"sender@example.com";
    [renderer setTemplateValue:field];
    template = [renderer renderTemplate:template];
    XCTAssertEqualObjects(template, rendered);
}

@end
