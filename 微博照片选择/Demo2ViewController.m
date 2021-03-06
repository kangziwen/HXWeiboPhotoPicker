//
//  Demo2ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo2ViewController.h" 
#import "HXPhotoPicker.h"

static const CGFloat kPhotoViewMargin = 12.0;

@interface Demo2ViewController ()<HXPhotoViewDelegate,UIImagePickerControllerDelegate>

@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) HXDatePhotoToolManager *toolManager;

@end

@implementation Demo2ViewController

- (HXDatePhotoToolManager *)toolManager {
    if (!_toolManager) {
        _toolManager = [[HXDatePhotoToolManager alloc] init];
    }
    return _toolManager;
}

- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.openCamera = YES;
        _manager.configuration.lookLivePhoto = YES;
        _manager.configuration.photoMaxNum = 4;
        _manager.configuration.videoMaxNum = 6;
        _manager.configuration.maxNum = 10;
        _manager.configuration.videoMaxDuration = 500.f;
        _manager.configuration.saveSystemAblum = NO;
//        _manager.configuration.reverseDate = YES;
        _manager.configuration.showDateSectionHeader = NO;
        _manager.configuration.selectTogether = NO;
//        _manager.configuration.rowCount = 3;
//        _manager.configuration.themeColor = [UIColor orangeColor];
//        _manager.configuration.navigationTitleSynchColor = YES;
        _manager.configuration.navigationBar = ^(UINavigationBar *navigationBar) {
//            navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor orangeColor]};
        };
        
//        _manager.configuration.movableCropBox = YES;
//        _manager.configuration.movableCropBoxEditSize = YES;
//        _manager.configuration.movableCropBoxCustomRatio = CGPointMake(1, 1);
        
        __weak typeof(self) weakSelf = self;
//        _manager.configuration.useCustomCamera = YES;
        _manager.configuration.shouldUseCamera = ^(UIViewController *viewController, HXPhotoConfigurationCameraType cameraType, HXPhotoManager *manager) {
            
            // 这里拿使用系统相机做例子
            UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
            imagePickerController.delegate = (id)weakSelf;
            imagePickerController.allowsEditing = NO;
            NSString *requiredMediaTypeImage = ( NSString *)kUTTypeImage;
            NSString *requiredMediaTypeMovie = ( NSString *)kUTTypeMovie;
            NSArray *arrMediaTypes;
            if (cameraType == HXPhotoConfigurationCameraTypePhoto) {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeImage,nil];
            }else if (cameraType == HXPhotoConfigurationCameraTypeVideo) {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeMovie,nil];
            }else {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeImage, requiredMediaTypeMovie,nil];
            }
            [imagePickerController setMediaTypes:arrMediaTypes];
            // 设置录制视频的质量
            [imagePickerController setVideoQuality:UIImagePickerControllerQualityTypeHigh];
            //设置最长摄像时间
            [imagePickerController setVideoMaximumDuration:60.f];
            imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePickerController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
            imagePickerController.modalPresentationStyle=UIModalPresentationOverCurrentContext;
            [viewController presentViewController:imagePickerController animated:YES completion:nil];
        };
    }
    return _manager;
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    HXPhotoModel *model;
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        model = [HXPhotoModel photoModelWithImage:image];
        if (self.manager.configuration.saveSystemAblum) {
            [HXPhotoTools savePhotoToCustomAlbumWithName:self.manager.configuration.customAlbumName photo:model.thumbPhoto];
        }
    }else  if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *url = info[UIImagePickerControllerMediaURL];
        NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                         forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
        float second = 0;
        second = urlAsset.duration.value/urlAsset.duration.timescale;
        model = [HXPhotoModel photoModelWithVideoURL:url videoTime:second];
        if (self.manager.configuration.saveSystemAblum) {
            [HXPhotoTools saveVideoToCustomAlbumWithName:self.manager.configuration.customAlbumName videoURL:url];
        }
    }
    if (self.manager.configuration.useCameraComplete) {
        self.manager.configuration.useCameraComplete(model);
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
//    self.navigationController.navigationBar.translucent = NO;
//    self.automaticallyAdjustsScrollViewInsets = YES;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    CGFloat width = scrollView.frame.size.width;
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager];
    photoView.frame = CGRectMake(kPhotoViewMargin, kPhotoViewMargin, width - kPhotoViewMargin * 2, 0);
    photoView.delegate = self;
    photoView.outerCamera = YES;
    photoView.backgroundColor = [UIColor whiteColor];
    [scrollView addSubview:photoView];
    self.photoView = photoView; 

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册/相机" style:UIBarButtonItemStylePlain target:self action:@selector(didNavBtnClick)];
}
- (void)didNavBtnClick {
    [self.photoView goPhotoViewController];
}

- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    NSSLog(@"所有:%ld - 照片:%ld - 视频:%ld",allList.count,photos.count,videos.count);
    NSSLog(@"所有:%@ - 照片:%@ - 视频:%@",allList,photos,videos);
    
    [HXPhotoTools selectListWriteToTempPath:allList requestList:^(NSArray *imageRequestIds, NSArray *videoSessions) {
        NSSLog(@"requestIds - image : %@ \nsessions - video : %@",imageRequestIds,videoSessions);
    } completion:^(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls) {
        NSSLog(@"allUrl - %@\nimageUrls - %@\nvideoUrls - %@",allUrl,imageUrls,videoUrls);
    } error:^{
        NSSLog(@"失败");
    }];
    
//    [self.toolManager getSelectedImageList:allList success:^(NSArray<UIImage *> *imageList) {
//
//    } failed:^{
//
//    }];
//    [self.toolManager cancelGetImageList];
//    [HXPhotoTools getImageForSelectedPhoto:photos type:HXPhotoToolsFetchHDImageType completion:^(NSArray<UIImage *> *images) {
//        NSSLog(@"%@",images);
//        for (UIImage *image in images) {
//            if (image.images.count > 0) {
//                // 到这里了说明这个image  是个gif图
//            }
//        }
//    }];
    
//    将HXPhotoModel模型数组转化成HXPhotoResultModel模型数组  - 已按选择顺序排序
//    !!!!  必须是全部类型的那个数组 就是 allList 这个数组  !!!!
    /**  不推荐使用此方法,请使用一键写入临时目录的方法  */
//    [HXPhotoTools getSelectedListResultModel:allList complete:^(NSArray<HXPhotoResultModel *> *alls, NSArray<HXPhotoResultModel *> *photos, NSArray<HXPhotoResultModel *> *videos) {
//        NSSLog(@"\n全部类型:%@\n照片:%@\n视频:%@",alls,photos,videos);
//    }];
    
//    [HXPhotoTools getSelectedPhotosFullSizeImageUrl:photos complete:^(NSArray<NSURL *> *imageUrls) {
//        NSSLog(@"%@",imageUrls);
//    }];
    
//    HXPhotoModel *model = allList.firstObject;
//    if ([model.avAsset isKindOfClass:[AVURLAsset class]]) {
//        AVURLAsset *urlAsset = (AVURLAsset *)model.avAsset;
//        NSSLog(@"%@",urlAsset.URL);
//    }
//    // 获取相册里照片原图URL  如果是相机拍的照片且没有保存到系统相册时 此方法无效
//    [HXPhotoTools getFullSizeImageUrlFor:model complete:^(NSURL *url) {
//        NSSLog(@"%@",url);
//    }];
    
//    for (HXPhotoModel *model in allList) {
//        NSLog(@"\n%@\n%@",model.thumbPhoto,model.previewPhoto);
//    }
    
    /*
     // 获取image - PHImageManagerMaximumSize 是原图尺寸 - 通过相册获取时有用 / 通过相机拍摄的无效
     CGSize size = PHImageManagerMaximumSize; // 通过传入 size 的大小来控制图片的质量
     [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:size resizeMode:PHImageRequestOptionsResizeModeFast completion:^(UIImage *image, NSDictionary *info) {
     NSSLog(@"%@",image);
     }];
     
        // 这里的size 是普通图片的时候  想要更高质量的图片 可以把 1.5 换成 2 或者 3
            如果觉得内存消耗过大可以 调小一点
     
         CGSize size = CGSizeMake(model.endImageSize.width * 1.5, model.endImageSize.height * 1.5);
     
        // 这里是判断图片是否过长 因为图片如果长了 上面的size就显的有点小了获取出来的图片就变模糊了,所以这里把宽度 换成了屏幕的宽度,这个可以保证即不影响内存也不影响质量 如果觉得质量达不到你的要求,可以乘上 1.5 或者 2 . 当然你也可以不按我这样给size,自己测试怎么给都可以
         if (model.endImageSize.height > model.endImageSize.width / 9 * 20) {
            size = CGSizeMake([UIScreen mainScreen].bounds.size.width, model.endImageSize.height);
         }
     */
    
    /*
     
    // 获取图片资源
    [photos enumerateObjectsUsingBlock:^(HXPhotoModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        // 封面小图
        model.thumbPhoto;
     
        // 预览大图 - 只有在查看大图的时候选中之后才有值
        model.previewPhoto;
        
        // imageData  - 这个字段没有值 请根据指定方法获取
        model.imageData;
        
        // isCloseLivePhoto 判断当前图片是否关闭了 livePhoto 功能 YES-关闭 NO-开启
        model.isCloseLivePhoto;
        
        // 获取imageData - 通过相册获取时有用 / 通过相机拍摄的无效
        [HXPhotoTools FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
            NSSLog(@"%@",imageData);
        }];
        
        // 获取image - PHImageManagerMaximumSize 是原图尺寸 - 通过相册获取时有用 / 通过相机拍摄的无效
        CGSize size = PHImageManagerMaximumSize; // 通过传入 size 的大小来控制图片的质量
        [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:size resizeMode:PHImageRequestOptionsResizeModeFast completion:^(UIImage *image, NSDictionary *info) {
            NSSLog(@"%@",image);
        }];
        
        // 如果是通过相机拍摄的照片只有 thumbPhoto、previewPhoto和imageSize 这三个字段有用可以通过 type 这个字段判断是不是通过相机拍摄的
        if (model.type == HXPhotoModelMediaTypeCameraPhoto);
    }];
    
    // 如果是相册选取的视频 要获取视频URL 必须先将视频压缩写入文件,得到的文件路径就是视频的URL 如果是通过相机录制的视频那么 videoURL 这个字段就是视频的URL 可以看需求看要不要压缩
    [videos enumerateObjectsUsingBlock:^(HXPhotoModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
     
        // 视频封面
        model.thumbPhoto;
         
        // 视频封面 大图 - 只有在查看大图的时候选中之后才有值
        model.previewPhoto; 
        
     
    }];
    
    // 判断照片、视频 或 是否是通过相机拍摄的
    [allList enumerateObjectsUsingBlock:^(HXPhotoModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            // 通过相机录制的视频
        }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            // 通过相机拍摄的照片
        }else if (model.type == HXPhotoModelMediaTypePhoto) {
            // 相册里的照片
        }else if (model.type == HXPhotoModelMediaTypePhotoGif) {
            // 相册里的GIF图
        }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            // 相册里的livePhoto
        }
    }];
     
     */
}
- (void)photoView:(HXPhotoView *)photoView deleteNetworkPhoto:(NSString *)networkPhotoUrl {
    NSSLog(@"%@",networkPhotoUrl);
}

- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    NSSLog(@"%@",NSStringFromCGRect(frame));
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
    
}

//
//// 压缩视频并写入沙盒文件
//- (void)compressedVideoWithURL:(id)url success:(void(^)(NSString *fileName))success failure:(void(^)())failure
//{
//    AVURLAsset *avAsset;
//    if ([url isKindOfClass:[NSURL class]]) {
//        avAsset = [AVURLAsset assetWithURL:url];
//    }else if ([url isKindOfClass:[AVAsset class]]) {
//        avAsset = (AVURLAsset *)url;
//    }
//    
//    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
//    
//    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
//        
//        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
//        
//        NSString *fileName = @""; // 这里是自己定义的文件路径
//        
//        NSDate *nowDate = [NSDate date];
//        NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
//        
//        NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
//        fileName = [fileName stringByAppendingString:dateStr];
//        fileName = [fileName stringByAppendingString:numStr];
//        
//        // ````` 这里取的是时间加上一些随机数  保证每次写入文件的路径不一样
//        fileName = [fileName stringByAppendingString:@".mp4"]; // 视频后缀
//        NSString *fileName1 = [NSTemporaryDirectory() stringByAppendingString:fileName]; //文件名称
//        exportSession.outputURL = [NSURL fileURLWithPath:fileName1];
//        exportSession.outputFileType = AVFileTypeMPEG4;
//        exportSession.shouldOptimizeForNetworkUse = YES;
//        
//        [exportSession exportAsynchronouslyWithCompletionHandler:^{
//            
//            switch (exportSession.status) {
//                case AVAssetExportSessionStatusCancelled:
//                    break;
//                case AVAssetExportSessionStatusCompleted:
//                {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if (success) {
//                            success(fileName1);
//                        }
//                    });
//                }
//                    break;
//                case AVAssetExportSessionStatusExporting:
//                    break;
//                case AVAssetExportSessionStatusFailed:
//                {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if (failure) {
//                            failure();
//                        }
//                    });
//                }
//                    break;
//                case AVAssetExportSessionStatusUnknown:
//                    break;
//                case AVAssetExportSessionStatusWaiting:
//                    break;
//                default:
//                    break;
//            }
//        }];
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
