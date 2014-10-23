//
//  ViewController.m
//  APISFeedSample
//
//  Created by 植田 洋次 on 2014/10/15.
//  Copyright (c) 2014年 Yoji Ueda. All rights reserved.
//

#import "ViewController.h"
#import "CollectionViewCell.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface ViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) UIRefreshControl *refreshControl;
//JSON APIから取得するデータを格納
@property (strong, nonatomic) NSArray *collections;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //配列を初期化
    self.collections = [[NSMutableArray alloc] init];
    
    //RefreshControl
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    self.collectionView.alwaysBounceVertical = YES;
    
    [self refreshAction:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.collections count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    //取り出し
    NSDictionary *dict = self.collections[(NSUInteger)indexPath.row];
    
    //cellのサイズ調整
    //http://stackoverflow.com/questions/24750158/autoresizing-issue-of-uicollectionviewcell-contentviews-frame-in-storyboard-pro
    cell.contentView.frame = cell.bounds;
    cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //画像
    NSString *imageUrl = [NSString stringWithFormat:@"%@/%@/%@/%@/%@/_bin", @"https://api-datastore.appiaries.com/v1/bin", @"_sandbox", @"APISFeedSample", @"imageFile", dict[@"imageObjectId"]];
    [cell.mainImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl]];
    //テキスト
    cell.commentLabel.text = dict[@"comment"];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = self.view.frame.size.width;
    return CGSizeMake(width, width);
}

#pragma mark - private
-(void)refreshAction:(id)sender
{
    [self.refreshControl beginRefreshing];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    //JSON Dataの条件を指定します。今回は絞込条件なし、データ作成順にソートする
    NSDictionary *parameters = @{@"order": @"createdAt"};
    
    //URLを生成
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@/%@/-;order=createdAt", @"https://api-datastore.appiaries.com/v1/dat", @"_sandbox", @"APISFeedSample", @"post"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:urlString parameters:parameters
         success:^(NSURLSessionDataTask *task, id responseObject) {
             //結果は「_objs」の配列で取得できる
             NSArray *objs = [(NSDictionary*)responseObject objectForKey:@"_objs"];
             
             NSMutableArray *m = [NSMutableArray new];
             for (NSDictionary *dict in objs) {
                 //配列にデータを追加
                 [m addObject:dict];
             }
             self.collections = [m mutableCopy];
             
             //テーブルを更新
             [self.collectionView reloadData];
             
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [self.refreshControl endRefreshing];
         } failure:^(NSURLSessionDataTask *task, NSError *error) {
             //Error
             NSLog(@"error: %@",error);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [self.refreshControl endRefreshing];
         }
    ];
}

@end
