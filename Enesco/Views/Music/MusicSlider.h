//
//  MusicSlider.h
//  Aufree
//
//  Created by Aufree on 11/7/15.
//  Copyright © 2015 The EST Group. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MusicSlider;

@protocol MusicSliderDelegate <NSObject>

@optional

/// 松手回调
/// @param musicSlider 自身
- (void)touchesEndedWithMusicSlider:(nonnull __kindof MusicSlider *)musicSlider;

@end

@interface MusicSlider : UISlider

/// 代理
@property (nullable, nonatomic, strong) id <MusicSliderDelegate> delegate;

@end
