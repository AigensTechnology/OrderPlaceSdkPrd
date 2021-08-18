//
//
//  
//
//  Created by lbxia on 15/10/21.
//  Copyright © 2015年 lbxia. All rights reserved.
//

#import "LBXScanNativeViewController.h"
#import "StyleDIY.h"
#import "Global.h"
#import "LBXScanTypes.h"

@interface LBXScanNativeViewController ()
//@property (nonatomic, strong) UIView *videoView;

/*!
 *  扫码结果返回
 */
@property(nonatomic,copy)void(^blockScanResult)(NSString *result);


@end

@implementation LBXScanNativeViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.view.backgroundColor = [UIColor blackColor];
    
//    self.title = [NSString stringWithFormat:@"native 支持横竖屏切换 - %@",self.continuous ? @"连续扫码" : @"不连续扫码"];
    
    
    
    [self drawScanView];
    
    [self requestCameraPemissionWithResult:^(BOOL granted) {
        
        if (granted) {
            
            [self startScan];
        }
    }];
    
    [self addCancelBtn];

}


- (instancetype)initWithSuccess: (void(^)(NSString *result))success {
    
//    LBXScanNativeViewController* vc = [LBXScanNativeViewController new];
//    vc.listScanTypes = @[[StyleDIY nativeCodeWithType:[Global sharedManager].scanCodeType]];
//    vc.cameraInvokeMsg = @"";
//
//    //开启只识别框内,ZBar暂不支持
//    vc.isOpenInterestRect = NO;
//    vc.continuous = false;
//
//    vc.style = [StyleDIY weixinStyle];
//    vc.orientation = [StyleDIY videoOrientation];
    
    if (self = [super init]) {
        self.listScanTypes = @[[StyleDIY nativeCodeWithType:[Global sharedManager].scanCodeType]];
        self.cameraInvokeMsg = @"";
        
        //开启只识别框内,ZBar暂不支持
        self.isOpenInterestRect = NO;
        self.continuous = false;
        
        self.style = [StyleDIY weixinStyle];
        self.orientation = [StyleDIY videoOrientation];
        self.blockScanResult = success;
    }
    return self;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGRect rect = self.view.frame;
    rect.origin = CGPointMake(0, 0);
    
    self.qRScanView.frame = rect;
    
    self.cameraPreView.frame = self.view.bounds;
    
    if (_scanObj) {
        [_scanObj setVideoLayerframe:self.cameraPreView.frame];
    }
    
    [self.qRScanView stopScanAnimation];
    
    [self.qRScanView startScanAnimation];
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.firstLoad) {
        [self reStartDevice];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopScan];

    [self.qRScanView stopScanAnimation];
}

//绘制扫描区域
- (void)drawScanView
{
    if (!self.qRScanView)
    {
        self.qRScanView = [[LBXScanView alloc]initWithFrame:self.view.bounds style:self.style];
        
        [self.view insertSubview:self.qRScanView atIndex:1];
    }
    
    if (!self.cameraInvokeMsg) {
        
        self.cameraInvokeMsg = NSLocalizedString(@"wating...", nil);
    }
}

- (void)addCancelBtn {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.contentEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5);
    btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.layer.cornerRadius = 5;
    if (!self.language || [self.language isEqual: @""] ) {
        self.language = @"en";
    }
    NSString *text = [self.language isEqual:@"en"] ? @"Cancel" : @"取消";
    [btn setTitle: text forState: UIControlStateNormal];
    [btn setBackgroundColor: [UIColor lightGrayColor]];
    [btn setTitleColor:[UIColor whiteColor] forState:(UIControlState)UIControlStateNormal];
    [btn addTarget:self action:@selector(cancelClicked) forControlEvents:(UIControlEventTouchUpInside)];
    btn.titleLabel.font = [UIFont systemFontOfSize: 16.0];
    [self.view addSubview:btn];
    
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:btn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:btn.superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-20];
    NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:btn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:btn.superview attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:btn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:70];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:btn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:44];
    [self.view addConstraint:bottomConstraint];
    [self.view addConstraint:centerConstraint];
    [self.view addConstraint:width];
    [self.view addConstraint:height];
    
}
- (void)cancelClicked {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)reStartDevice
{
    [self refreshLandScape];
    
    [self.qRScanView startDeviceReadyingWithText:self.cameraInvokeMsg];
    
    _scanObj.orientation = [self videoOrientation];
    [_scanObj startScan];
}

//启动设备
- (void)startScan
{
    if (!self.cameraPreView) {
        
        CGRect frame = self.view.bounds;
        
        UIView *videoView = [[UIView alloc]initWithFrame:frame];
        videoView.backgroundColor = [UIColor clearColor];
        [self.view insertSubview:videoView atIndex:0];
        
        self.cameraPreView = videoView;
    }
    
    __weak __typeof(self) weakSelf = self;

    if (!_scanObj )
    {
        CGRect cropRect = CGRectZero;
        
        if (self.isOpenInterestRect) {
            
            //设置只识别框内区域
            cropRect = [LBXScanView getScanRectWithPreView:self.view style:self.style];
        }
        

        self.scanObj = [[LBXScanNative alloc]initWithPreView:self.cameraPreView ObjectType:self.listScanTypes cropRect:cropRect videoMaxScale:^(CGFloat maxScale) {
            [weakSelf setVideoMaxScale:maxScale];
            
        }  success:^(NSArray<LBXScanResult *> *array) {
            
            [weakSelf handScanNative:array];
        }];
        [_scanObj setNeedCaptureImage:self.isNeedScanImage];
        //是否需要返回条码坐标
        _scanObj.needCodePosion = YES;
        _scanObj.continuous = self.continuous;
    }
    
    
    _scanObj.onStarted = ^{
        
        [weakSelf.qRScanView stopDeviceReadying];
        [weakSelf.qRScanView startScanAnimation];
    };
    
    //可动态修改
    _scanObj.orientation = [self videoOrientation];
    
    
    [self.qRScanView startDeviceReadyingWithText:self.cameraInvokeMsg];

    
#if TARGET_OS_SIMULATOR
    
#else
     [_scanObj startScan];
#endif
    
   
    
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)handScanNative:(NSArray<LBXScanResult *> *)array
{
//    [self scanResultWithArray:array];
    
    if (!array ||  array.count < 1)
    {
        [self reStartDevice];
        return;
    }
    
    LBXScanResult *scanResult = array[0];
    
    NSString*strResult = scanResult.strScanned;
    if (!strResult) {
        [self reStartDevice];
        return;
    }
    __weak __typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.blockScanResult) {
            weakSelf.blockScanResult(strResult);
        }
    }];
    
}

- (void)dealloc {
    NSLog(@"dealloc scan");
}

- (void)setVideoMaxScale:(CGFloat)maxScale
{
    
}

- (void)stopScan
{
    [_scanObj stopScan];
}

//开关闪光灯
- (void)openOrCloseFlash
{
    [_scanObj changeTorch];
    
    
    self.isOpenFlash =!self.isOpenFlash;
}


#pragma mark- 旋转
- (void)refreshLandScape
{
    if ([self isLandScape]) {
        
        self.style.centerUpOffset = 20;
        
        CGFloat w = [UIScreen mainScreen].bounds.size.width;
        CGFloat h = [UIScreen mainScreen].bounds.size.height;
        
        CGFloat max = MAX(w, h);
        
        CGFloat min = MIN(w, h);
        
        CGFloat scanRetangeH = min / 3;
        
        self.style.xScanRetangleOffset = max / 2 - scanRetangeH / 2;
    }
    else
    {
        self.style.centerUpOffset = 40;
        self.style.xScanRetangleOffset = 60;
    }
    
    self.qRScanView.viewStyle = self.style;
    [self.qRScanView setNeedsDisplay];
}


- (void)statusBarOrientationChanged:(NSNotification*)notification
{
    [self refreshLandScape];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    if (_scanObj) {
        _scanObj.orientation = [self videoOrientation];
    }
    
    [self.qRScanView stopScanAnimation];
    
    [self.qRScanView startScanAnimation];
}

#pragma mark --打开相册并识别图片

/*!
 *  打开本地照片，选择图片识别
 */
- (void)openLocalPhoto:(BOOL)allowsEditing
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    picker.delegate = self;
   
    //部分机型有问题
    picker.allowsEditing = allowsEditing;
    
    
    [self presentViewController:picker animated:YES completion:nil];
}



- (void)recognizeImageWithImage:(UIImage*)image
{
    __weak __typeof(self) weakSelf = self;
    
    if (@available(iOS 8.0, *)) {
        [LBXScanNative recognizeImage:image success:^(NSArray<LBXScanResult *> *array) {
            [weakSelf scanResultWithArray:array];
        }];
    }
}




@end
