//
//  MusicListViewController.m
//  Enesco
//
//  Created by Aufree on 11/30/15.
//  Copyright © 2015 The EST Group. All rights reserved.
//

#import "MusicListViewController.h"
#import "MusicViewController.h"
#import "MusicListCell.h"
#import "MusicIndicator.h"
#import "MBProgressHUD.h"
#import <AVFoundation/AVFoundation.h>

@interface MusicListViewController () <MusicViewControllerDelegate, MusicListCellDelegate>
@property (nonatomic, strong) NSMutableArray *musicEntities;
@property (nonatomic, assign) NSInteger currentIndex;
@end

@implementation MusicListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.navigationItem.title = @"一些事一些情";
    [self headerRefreshing];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self createIndicatorView];
    [self.tableView reloadData];
}

# pragma mark - Custom right bar button item

- (void)createIndicatorView {
    MusicIndicator *indicator = [MusicIndicator sharedInstance];
    indicator.hidesWhenStopped = NO;
    indicator.tintColor = [UIColor redColor];
    
//    if (indicator.state != NAKPlaybackIndicatorViewStatePlaying) {
//        indicator.state = NAKPlaybackIndicatorViewStatePlaying;
//        indicator.state = NAKPlaybackIndicatorViewStateStopped;
//    } else {
//        indicator.state = NAKPlaybackIndicatorViewStatePlaying;
//    }
    indicator.state = indicator.state;
    
    [self.navigationController.navigationBar addSubview:indicator];
    
    UITapGestureRecognizer *tapInditator = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapIndicator)];
    tapInditator.numberOfTapsRequired = 1;
    [indicator addGestureRecognizer:tapInditator];
}

- (void)handleTapIndicator {
    MusicViewController *musicVC = [MusicViewController sharedInstance];
    if (musicVC.musicEntities.count == 0) {
        [self showMiddleHint:@"暂无正在播放的歌曲"];
        return;
    }
    musicVC.dontReloadMusic = YES;
    [self presentToMusicViewWithMusicVC:musicVC];
}

# pragma mark - Load data from server

- (void)headerRefreshing {
    
    NSMutableArray<MusicEntity *> *arrM = @[].mutableCopy;
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSFileManager *fileManger = [NSFileManager defaultManager];
    BOOL isDir = NO;
    NSNumber *lastSongIndex = nil;
    if ([fileManger fileExistsAtPath:path isDirectory:&isDir] && isDir) {
        NSString *lastSongName = [NSUserDefaults.standardUserDefaults objectForKey:pathKey];
        NSArray *songArray = [fileManger contentsOfDirectoryAtPath:path error:nil];
        if (songArray.count) {
            songArray = [songArray sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
                return [obj1 compare:obj2];
            }];
        }
        NSString *songPath = nil;
        for (NSString *name in songArray) {
            songPath = [path stringByAppendingPathComponent:name];
            if ([fileManger fileExistsAtPath:songPath isDirectory:&isDir] && !isDir) {
                MusicEntity *music = [MusicEntity new];
                music.musicUrl = songPath;
                music.name = name;
                music.artistName = @"双低";
                [arrM addObject:music];
                if ([name isEqualToString:lastSongName]) {
                    lastSongIndex = @([songArray indexOfObject:name]);
                }
            }
        }
    }
    //    NSDictionary *musicsDict = [self dictionaryWithContentsOfJSONString:@"music_list.json"];
    //    [MusicEntity arrayOfEntitiesFromArray:musicsDict[@"data"]].mutableCopy;
    self.musicEntities = arrM;
    [self.tableView reloadData];
    
    if (lastSongIndex) {
        [self handleDidSelectRowAtIndexPath:[NSIndexPath indexPathForRow:lastSongIndex.intValue inSection:0] prePlay:YES];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastSongIndex.intValue inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (NSDictionary *)dictionaryWithContentsOfJSONString:(NSString *)fileLocation {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[fileLocation stringByDeletingPathExtension] ofType:@"json"];
    NSLog(@"%@ 播放路径",filePath);
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions error:&error];
    if (error != nil) return nil;
    return result;
}

- (void)handleDidSelectRowAtIndexPath:(NSIndexPath *)indexPath prePlay:(BOOL)prePlay {
    
    if (_delegate && [_delegate respondsToSelector:@selector(playMusicWithSpecialIndex:)]) {
        [_delegate playMusicWithSpecialIndex:indexPath.row];
    } else {
        MusicViewController *musicVC = [MusicViewController sharedInstance];
        if (![musicVC.currentPlayingMusic.musicUrl isEqualToString:[_musicEntities[indexPath.row] musicUrl]]) {
            musicVC.musicTitle = self.navigationItem.title;
            musicVC.musicEntities = _musicEntities;
            musicVC.delegate = self;
            musicVC.specialIndex = indexPath.row;
            musicVC.dontReloadMusic = NO;
            if (prePlay) { musicVC.prePlay = YES; }
        }
        else {
            musicVC.dontReloadMusic = YES;
        }
        [self presentToMusicViewWithMusicVC:musicVC];
    }
    [self showMiddleHint:@"loading"];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

# pragma mark - Tableview delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self handleDidSelectRowAtIndexPath:indexPath prePlay:NO];
}

# pragma mark - Jump to music view

- (void)presentToMusicViewWithMusicVC:(MusicViewController *)musicVC {
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:musicVC];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

# pragma mark - Update music indicator state

// 播放状态变更回调
- (void)updatePlaybackIndicatorOfVisisbleCells {
    
    [self.tableView reloadData];
}

# pragma mark - Tableview datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 57;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _musicEntities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *musicListCell = @"musicListCell";
    MusicEntity *music = _musicEntities[indexPath.row];
    MusicListCell *cell = [tableView dequeueReusableCellWithIdentifier:musicListCell];
    cell.musicNumber = indexPath.row + 1;
    cell.musicEntity = music;
    cell.delegate = self;
    cell.state = NAKPlaybackIndicatorViewStateStopped;
    
    MusicViewController *musicVC = [MusicViewController sharedInstance];
    if ([musicVC.currentPlayingMusic.name isEqualToString:music.name]) {
        MusicIndicator *indicator = [MusicIndicator sharedInstance];
        cell.state = indicator.state;
    }
    return cell;
}
         
# pragma mark - HUD
         
- (void)showMiddleHint:(NSString *)hint {
     UIView *view = [[UIApplication sharedApplication].delegate window];
     MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
     hud.userInteractionEnabled = NO;
     hud.mode = MBProgressHUDModeText;
     hud.labelText = hint;
     hud.labelFont = [UIFont systemFontOfSize:15];
     hud.margin = 10.f;
     hud.yOffset = 0;
     hud.removeFromSuperViewOnHide = YES;
     [hud hide:YES afterDelay:1];
}

@end
