//
//  PostViewController.m
//  APISFeedSample
//
//  Created by 植田 洋次 on 2014/10/17.
//  Copyright (c) 2014年 Yoji Ueda. All rights reserved.
//

#import "PostViewController.h"
#import "UIImage+Extensions.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface PostViewController ()<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UITextView *commentTextView;

//選択した写真を一時的に保存する場所
@property (strong, nonatomic) UIImage *selectedImage;

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)saveButtonAction:(id)sender;
- (IBAction)photoButtonAction:(id)sender;

@end

@implementation PostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action
- (IBAction)cancelButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveButtonAction:(id)sender {
    
    //エラーチェック
    if (!self.selectedImage) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラー"
                                                        message:@"画像を選択して下さい"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];

    //画像を登録するURLを生成
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@/%@?proc=create&get=true&access_token=%@", @"https://api-datastore.appiaries.com/v1/bin", @"_sandbox", @"APISFeedSample", @"imageFile", @"app60433c173d722dc86abc41c6da"];
    
    //登録する画像
    NSData *imageData = UIImageJPEGRepresentation(self.selectedImage, 0.5);
    //パラメータ
    NSString *fileName = @"upload.jpeg";
    NSString *mimeType = @"image/jpeg";
    NSDictionary *parameters = @{@"_type": mimeType,
                                 @"_filename": fileName,
                                 };
    //File APIの呼び出し
    __weak typeof(self) weakSelf = self;
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:urlString parameters:parameters
        constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"_file" fileName:fileName mimeType:mimeType];
        }
        success:^(NSURLSessionDataTask *task, id responseObject) {
            [SVProgressHUD dismiss];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            //返り値からIDを取得
            NSString *objectId = [(NSDictionary*)responseObject objectForKey:@"_id"];
            //データ作成処理へ
            [weakSelf postDataWithObjectId:objectId];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            //error
            NSLog(@"error: %@",error);
            [SVProgressHUD dismiss];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
    ];
}

- (void)postDataWithObjectId:(NSString*)objectId
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    
    //データを登録するURLを生成
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@/%@?proc=create&get=true&access_token=%@", @"https://api-datastore.appiaries.com/v1/dat", @"_sandbox", @"APISFeedSample", @"post", @"app60433c173d722dc86abc41c6da"];
    
    //日時
    NSNumber *dateNumber = [NSNumber numberWithUnsignedLong:(unsigned long)[[NSDate date] timeIntervalSince1970]];
    
    //パラメータ
    NSDictionary *parameters = @{@"imageObjectId": objectId ?:@"",
                                 @"comment": self.commentTextView.text ?:@"",
                                 @"createdAt": dateNumber
                                 };
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //JSONリクエストとして送信
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        [SVProgressHUD dismiss];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        //成功！
        [SVProgressHUD showSuccessWithStatus:@"Success!"];
        
        //閉じる
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        //error
        NSLog(@"error: %@",error);
        
        [SVProgressHUD dismiss];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

- (IBAction)photoButtonAction:(id)sender {
    // カメラのアクションシートを作る
    UIActionSheet*  sheet;
    sheet = [[UIActionSheet alloc]
             initWithTitle:@"Choose"
             delegate:self
             cancelButtonTitle:@"Cancel"
             destructiveButtonTitle:nil
             otherButtonTitles:@"Library",@"Camera", nil];
    [sheet showInView:self.view];
}

//--------------------------------------------------------------//
#pragma mark -- UIActionSheetDelegate --
//--------------------------------------------------------------//
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // ボタンインデックスをチェックする
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    // ソースタイプを決定する
    UIImagePickerControllerSourceType   sourceType = 0;
    switch (buttonIndex) {
        case 0: {
            sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        }
        case 1: {
            sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        }
    }
    
    // 使用可能かどうかチェックする
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"ImagePickerNotAccess", nil)
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // イメージピッカーを作る
    UIImagePickerController*    imagePicker;
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType    = sourceType;
    imagePicker.delegate      = self;
    
    // イメージピッカーを表示する
    [self presentViewController:imagePicker animated:YES completion:nil];
}

//--------------------------------------------------------------//
#pragma mark -- UIImagePickerDelegate --
//--------------------------------------------------------------//
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //加工された画像を取得
    UIImage *image = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation];
    self.selectedImage = [image imageByCroppingSquare];
    //ボタンに画像を配置
    [self.photoButton setImage:self.selectedImage forState:UIControlStateNormal];
    [self.photoButton setTitle:@"" forState:UIControlStateNormal];
    
    // イメージピッカーを隠す
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker{
    // イメージピッカーを隠す
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
