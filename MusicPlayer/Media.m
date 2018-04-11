//
//  Media.m
//  MusicPlayer
//
//  Created by Sandeepa on 10/04/18.
//  Copyright © 2018 Sandeepa. All rights reserved.
//

#import "Media.h"

@implementation Media
- (instancetype)initWithMediaInfo:(NSMutableDictionary *)info
{
    self = [super init];
    if (!self) {
        return nil;
    }
    self.songName = info[@"name"];
    self.path = info[@"url"];
    self.duration =[[info objectForKey:@"duration"] floatValue];
    self.image = info[@"image"];
    return self;
}
@end
