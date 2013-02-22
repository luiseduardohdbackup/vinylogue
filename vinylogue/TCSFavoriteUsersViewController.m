//
//  TCSFavoriteUsersViewController.m
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSFavoriteUsersViewController.h"

#import "TCSUserNameViewController.h"
#import "TCSSettingsViewController.h"
#import "TCSWeeklyAlbumChartViewController.h"

#import "TCSSimpleTableDataSource.h"
#import "TCSSettingsCells.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

@interface TCSFavoriteUsersViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIBarButtonItem *settingsButton;

@property (nonatomic, strong) NSString *userName;
@property (nonatomic) NSUInteger playCountFilter;
@property (nonatomic, strong) NSMutableArray *friendsList; // array of strings

@property (nonatomic, strong) TCSSimpleTableDataSource *dataSource;

@end

@implementation TCSFavoriteUsersViewController

- (id)initWithUserName:(NSString *)userName playCountFilter:(NSUInteger)playCountFilter friendsList:(NSArray *)friendsList{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.userName = userName;
    self.playCountFilter = playCountFilter;
    self.friendsList = [NSMutableArray arrayWithArray:friendsList];
    
    // When navigation bar is present
    self.title = @"scrobblers";
  }
  return self;
}

- (void)loadView{
  self.view = [[UIView alloc] init];
  [self.view addSubview:self.tableView];
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setImage:[UIImage imageNamed:@"settings"] forState:UIControlStateNormal];
  [button addTarget:self action:@selector(doSettings:) forControlEvents:UIControlEventTouchUpInside];
  button.adjustsImageWhenHighlighted = YES;
  button.showsTouchWhenHighlighted = YES;
  button.size = CGSizeMake(40, 40);
  self.settingsButton = [[UIBarButtonItem alloc] initWithCustomView:button];
  self.navigationItem.leftBarButtonItem = self.settingsButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillLayoutSubviews{
  self.tableView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  
  [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated{
  [super viewDidAppear:animated];
  
  // Ugly hack to get rid of automatically added bottom borders
  [self removeStupidTableHeaderBorders];
}

- (void)didReceiveMemoryWarning{
  [super didReceiveMemoryWarning];

}

#pragma mark - private

- (void)removeStupidTableHeaderBorders{
  NSArray *allTableViewSubviews = [self.tableView subviews];
  for (UIView *view in allTableViewSubviews){
    if ([view isKindOfClass:[TCSSettingsHeaderCell class]]){
      [[[view subviews] lastObject] removeFromSuperview];
    }
  }
  [self.tableView setNeedsDisplay];
}

#pragma mark - actions

- (void)doSettings:(UIBarButtonItem *)button{
  @weakify(self);
  TCSSettingsViewController *settingsViewController = [[TCSSettingsViewController alloc] initWithPlayCountFilter:self.playCountFilter];
  
  // Subscribe to the play count filter signal and set ours if it changes
  [[settingsViewController playCountFilterSignal] subscribeNext:^(NSNumber *playCountFilter) {
    @strongify(self);
    self.playCountFilter = [playCountFilter unsignedIntegerValue];
  }];
  [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (NSString *)userNameForIndexPath:(NSIndexPath *)indexPath{
  NSString *userName;
  if (indexPath.section == 0){
    userName = self.userName;
  }else if (indexPath.section == 1){
    userName = [self.friendsList objectAtIndex:indexPath.row];
  }else{
    userName = @"";
    NSAssert(NO, @"Outside of section bounds");
  }
  return userName;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  if (section == 0){
    return 1;
  }else if (section == 1){
    return [self.friendsList count];
  }else{
    return 0;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  static NSString *CellIdentifier = @"TCSSettingsCell";
  TCSSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (!cell) {
    cell = [[TCSSettingsCell alloc] init];
  }
  
  NSString *userName = [self userNameForIndexPath:indexPath];
  [cell setTitleText:userName];
  cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  
  return cell;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
- (NSString *)titleForHeaderInSection:(NSInteger)section{
  if (section == 0){
    return @"me";
  }else{
    return @"friends";
  }
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
  static CGFloat verticalMargin = 10;
  
  UIFont *font = [TCSSettingsHeaderCell font];
  NSString *title = [self titleForHeaderInSection:section];
  
  CGFloat textHeight = [title sizeWithFont:font constrainedToSize:CGSizeMake(tableView.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height;
  if (textHeight > 0){
    return textHeight + verticalMargin * 2;
  }else{
    return 0;
  }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
  NSString *title = [self titleForHeaderInSection:section];
  
  TCSSettingsHeaderCell *cell = [[TCSSettingsHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"header"];
  [cell setTitleText:title];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSString *userName = [self userNameForIndexPath:indexPath];
  
  TCSWeeklyAlbumChartViewController *albumChartController = [[TCSWeeklyAlbumChartViewController alloc] initWithUserName:userName playCountFilter:self.playCountFilter];
  [self.navigationController pushViewController:albumChartController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
  static CGFloat verticalMargin = 7;
  
  UIFont *font = [TCSSettingsCell font];
  NSString *userName = [self userNameForIndexPath:indexPath];
  
  CGFloat textHeight = [userName sizeWithFont:font constrainedToSize:CGSizeMake(tableView.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height;
  if (textHeight > 0){
    return textHeight + verticalMargin * 2;
  }else{
    return 0;
  }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{

}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
  NSString *userName = [self userNameForIndexPath:indexPath];
  
  TCSUserNameViewController *userNameController = [[TCSUserNameViewController alloc] initWithUserName:userName headerShowing:NO];
  @weakify(self);
  [[userNameController userNameSignal] subscribeNext:^(NSString *userName){
    @strongify(self);
    if (indexPath.section == 0){
      self.userName = userName;
    }else{
      [self.friendsList replaceObjectAtIndex:indexPath.row withObject:userName];
    }
  }];
  [self.navigationController pushViewController:userNameController animated:YES];
}

#pragma mark - view getters

- (UITableView *)tableView{
  if (!_tableView){
    _tableView = [[UITableView alloc] init];
    _tableView.backgroundColor = WHITE_SUBTLE;
    _tableView.scrollsToTop = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
  }
  return _tableView;
}

@end
