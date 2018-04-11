//
//  Media.h
//  MusicPlayer
//
//  Created by Sandeepa on 10/04/18.
//  Copyright © 2018 Sandeepa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface Media : NSObject
@property (strong,nonatomic) NSString *songName;
@property (strong,nonatomic) NSString *path;
@property  UIImage *image;

@property  float duration;

- (instancetype)initWithMediaInfo:(NSMutableDictionary *)info;
@end
