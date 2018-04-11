//
//  ViewController.m
//  MusicPlayer
//
//  Created by Sandeepa on 10/04/18.
//  Copyright © 2018 Sandeepa. All rights reserved.
//

#import "ViewController.h"
@import MediaPlayer;
#import <AVFoundation/AVFoundation.h>
#import "Media.h"
@interface ViewController ()<MPMediaPickerControllerDelegate>
{
    BOOL isPlaying;
    MPMediaQuery *query;
    NSMutableArray *songsArr;
    AVPlayer *player;
    NSTimer *sliderTimer;
    float totalduration ;
    AVPlayerItem *playerItem;
    NSURL *fileUrl;
    int currentItem;
    Media *media;
}
@end

@implementation ViewController
#pragma mark  Lifecycle Methods
- (void)viewDidLoad {
    [super viewDidLoad];
    currentItem = 0;
    isPlaying = NO;
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus authorizationStatus) {
        if ( authorizationStatus == MPMediaLibraryAuthorizationStatusAuthorized ) {
            NSLog(@"Access given");
            MPMediaQuery *query = [[MPMediaQuery alloc] init];
            NSArray *items = [query items];
            songsArr = [NSMutableArray new];
            for (MPMediaItem *song in items) {
                NSString *songUrl = [song valueForProperty:MPMediaItemPropertyAssetURL];
                
                if (!songUrl) {
                    NSLog(@"Not a valid file");
                }
                else{
                    NSString *songName = [song valueForProperty:MPMediaItemPropertyTitle];
                    NSString *duration = [song valueForProperty:MPMediaItemPropertyPlaybackDuration];
                    
                    NSMutableDictionary *dict = [NSMutableDictionary new];
                    UIImage *artworkImage = [UIImage imageNamed:@"noImage"];
                    MPMediaItemArtwork *artwork = [song valueForProperty: MPMediaItemPropertyArtwork];
                    
                    if (artwork) {
                        artworkImage = [artwork imageWithSize: CGSizeMake (200, 200)];
                    }
                    
                    [dict setObject:songUrl forKey:@"url"];
                    [dict setObject:songName forKey:@"name"];
                    [dict setObject:duration forKey:@"duration"];
                    [dict setObject:artworkImage forKey:@"image"];
                    media = [[Media alloc] initWithMediaInfo:dict];
                    [songsArr addObject:media];
                }
            }
            // Background play
            AVAudioSession *audioSession = [AVAudioSession sharedInstance];
            NSError *setCategoryError = nil;
            BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
            NSError *activationError = nil;
            success = [audioSession setActive:YES error:&activationError];
        } else {
            NSLog(@"Permission denied");
        } }];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    // Turn off remote control event delivery & Resign as first responder
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    // Don't forget to call super
    
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Notification Method
-(void)itemDidFinishPlaying:(NSNotification*)not{
    currentItem ++;
    if (currentItem>songsArr.count-1) {
        currentItem = 0;
    }
    // Setting player item based on currentItem
    [self setPlayerItemAndDuration:currentItem];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark Player Actions
- (IBAction)playAction:(UIButton *)sender
{
    if (isPlaying) {
        [player pause];
        isPlaying =NO;
        [sender setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
    else{
        isPlaying = YES;
        [sender setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        // Setting player item based on currentItem
        [self setPlayerItemAndDuration:currentItem];
    }
}
- (IBAction)nextSong:(id)sender {
    currentItem ++;
    if (currentItem>songsArr.count-1) {
        currentItem = 0;
    }
    // Setting player item based on currentItem
    [self setPlayerItemAndDuration:currentItem];
}
- (IBAction)previousAction:(id)sender {
    currentItem --;
    if (currentItem<0) {
        currentItem = (int)songsArr.count - 1 ;
    }
    // Setting player item based on currentItem
    [self setPlayerItemAndDuration:currentItem];
    
}

#pragma mark Control center Methods
- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPreviousTrack:
                NSLog(@"prev");
                [self previousAction:self];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                NSLog(@"next");
                [self nextSong:self];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [self.playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
                [player play];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [player pause];
                [self.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
                break;
            case UIEventSubtypeRemoteControlEndSeekingForward:
                [self sliding:self];
                break;
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                [self sliding:self];
                break;
            default:
                break;
        }
    }
}
-(void)setControlCenter:(Media *)cDict{
    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(200, 200) requestHandler:^UIImage * _Nonnull(CGSize size) {
        return cDict.image;
    }];
    
    NSDictionary *info = @{ MPMediaItemPropertyArtist: cDict.songName,
                            MPMediaItemPropertyAlbumTitle: cDict.songName,
                            MPMediaItemPropertyTitle: cDict.songName,
                            MPMediaItemPropertyArtwork : albumArt,
                            MPMediaItemPropertyPlaybackDuration: [NSString stringWithFormat:@"%f",cDict.duration]
                            };
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
}
#pragma mark Slider settings
-(IBAction)sliding:(id)sender{
    
    CMTime newTime = CMTimeMakeWithSeconds(self.slider.value, 1);
    [player seekToTime:newTime];
}

-(void)setSlider{
    
    sliderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self    selector:@selector(updateSlider) userInfo:nil repeats:YES];
    self.slider.maximumValue = [self durationInSeconds];
    [_slider addTarget:self action:@selector(sliding:) forControlEvents:UIControlEventValueChanged];
    self.slider.value=0.0;
    self.slider.minimumValue = 0.0;
    self.slider.continuous = YES;
}

- (void)updateSlider {
    
    self.slider.maximumValue = [self durationInSeconds];
    self.slider.value = [self currentTimeInSeconds];
}

- (Float64)durationInSeconds {
    
    return totalduration;
}
- (Float64)currentTimeInSeconds {
    Float64 dur = CMTimeGetSeconds([player currentTime]);
    return dur;
}
#pragma mark setting player item with currentItem
-(void)setPlayerItemAndDuration : (int)currentItem {
    
    if (songsArr.count>0) {
        media = [songsArr objectAtIndex:currentItem];
        totalduration = media.duration;
        fileUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@",media.path]];
        self.imgVw.image = media.image;
        playerItem = [[AVPlayerItem alloc] initWithURL:fileUrl];
        [self setSlider];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [self setControlCenter:media];
        player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        [player play];
    }
    else{
        NSLog(@"No items found");
    }
}

@end
