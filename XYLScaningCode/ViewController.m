//
//  ViewController.m
//  XYLScaningCode
//
//  Created by 薛银亮 on 16/2/22.
//  Copyright © 2016年 薛银亮. All rights reserved.
//

#import "ViewController.h"
#import "XYLScaningCode.h"

@interface ViewController ()<UIAlertViewDelegate, AVCaptureMetadataOutputObjectsDelegate, XYLScanViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    AVCaptureDevice *frontCamera;  //前置摄像机
    AVCaptureDevice *backCamera;  //后置摄像机
    AVCaptureSession *session;         //捕捉对象
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureInput *input;              //输入流
    AVCaptureMetadataOutput *output;//输出流
    BOOL isTorchOn;
}

@property (nonatomic, assign) XYLScaningWarningTone tone;
@property (nonatomic, strong) XYLScanView *overView;    //扫码界面
@property(strong, nonatomic)XYLBinaryCodeView *binaryCodeView;  //二维码界面
@property(weak, nonatomic)XYLToolButton *scanButton;
@property(weak, nonatomic)XYLToolButton *payCodeButton;
@property(weak, nonatomic)UILabel *titleLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupButton];
    [self payCodeSelected];
    //设置生成二维码界面
    self.binaryCodeView = [[XYLBinaryCodeView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    //设置二维码的内容
    self.binaryCodeView.inputData = @"www.baidu.com";
    [self.view insertSubview:self.binaryCodeView atIndex:1];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if ([self.overView isDisplayedInScreen])
    {
        [session stopRunning];
        [self.overView removeFromSuperview];
        self.overView = nil;
    }else if([self.binaryCodeView isDisplayedInScreen])
    {
        [self.binaryCodeView removeFromSuperview];
        self.binaryCodeView = nil;
    }
}

-(void)setupButton
{
    //设置初始化标题
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 25, 80, 30)];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = @"付款码";
    titleLabel.font = [UIFont systemFontOfSize:23 weight:.5f];
    titleLabel.centerX = [UIScreen mainScreen].bounds.size.width / 2.0f;
    self.titleLabel = titleLabel;
    [self.view addSubview:titleLabel];
    
    UIButton *backButton = [[UIButton alloc]initWithFrame:CGRectMake(20, 25, 30, 30)];
    [backButton setImage:[UIImage imageNamed:@"Back Arrow"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonActioin:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    CGFloat buttonWH = 70;
    XYLToolButton *scanButton = [[XYLToolButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 1.5*buttonWH, [UIScreen mainScreen].bounds.size.height - 2*buttonWH, buttonWH, buttonWH)];
    [scanButton setTitle:@"扫码" forState:UIControlStateNormal];
    [scanButton setImage:[UIImage imageNamed:@"扫码"] forState:UIControlStateNormal];
    [scanButton addTarget:self action:@selector(scanSelected) forControlEvents:UIControlEventTouchUpInside];
    self.scanButton = scanButton;
    [self.view addSubview:scanButton];
    
    UILabel *scanLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.scanButton.frame), 80, 20)];
    scanLabel.text = @"(主扫，付款)";
    scanLabel.textColor = [UIColor whiteColor];
    scanLabel.font = [UIFont systemFontOfSize:13];
    scanLabel.centerX = scanButton.centerX;
    [self.view addSubview:scanLabel];
    
    XYLToolButton *payCodeButton = [[XYLToolButton alloc]initWithFrame:CGRectMake(buttonWH / 2.0, [UIScreen mainScreen].bounds.size.height - 2*buttonWH, buttonWH, buttonWH)];
    [payCodeButton setTitle:@"付款码" forState:UIControlStateNormal];
    [payCodeButton setImage:[UIImage imageNamed:@"付款码"] forState:UIControlStateNormal];
    [payCodeButton addTarget:self action:@selector(payCodeSelected) forControlEvents:UIControlEventTouchUpInside];
    self.payCodeButton = payCodeButton;
    [self.view addSubview:payCodeButton];
    
    UILabel *payCodeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.payCodeButton.frame), 80, 20)];
    payCodeLabel.text = @"(被扫，付款)";
    payCodeLabel.textColor = [UIColor whiteColor];
    payCodeLabel.font = [UIFont systemFontOfSize:13];
    payCodeLabel.centerX = payCodeButton.centerX;
    [self.view addSubview:payCodeLabel];
}

#pragma mark - 按钮点击
//点击返回
- (void)backButtonActioin:(UIButton *)button
{
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//点击付款码
-(void)payCodeSelected
{
    if (![self.binaryCodeView isDisplayedInScreen])
    {
        self.overView.hidden = YES;
        self.binaryCodeView.hidden = NO;
    }
}

//点击扫码
-(void)scanSelected
{
    if (![self.overView isDisplayedInScreen])
    {
#if TARGET_IPHONE_SIMULATOR
    UIAlertController *simulatorAlert = [UIAlertController alertControllerWithTitle:nil message:@"虚拟机不支持相机" preferredStyle:UIAlertControllerStyleActionSheet];
    [simulatorAlert addAction:[UIAlertAction actionWithTitle:@"好吧" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        return;
    }]];
    [self presentViewController:simulatorAlert animated:YES completion:nil];

#elif TARGET_OS_IPHONE
        
    //判断相机权限
    [self isVideoUseable];
    self.binaryCodeView.hidden = YES;
    if (self.overView) {
        self.overView.hidden = NO;
    }else{
        //添加扫面界面视图
        [self initOverView];
        [self initCapture];
        [self config];
        [self initUI];
        [self addGesture];
    }
#endif
    }
}

-(void)isVideoUseable
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        UIAlertController *simulatorAlert = [UIAlertController alertControllerWithTitle:nil message:@"相机权限未开通，请打开" preferredStyle:UIAlertControllerStyleActionSheet];
        [simulatorAlert addAction:[UIAlertAction actionWithTitle:@"好吧" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            return;
        }]];
        [self presentViewController:simulatorAlert animated:YES completion:nil];
    }
}

/**
 *  添加扫码视图
 */
- (void)initOverView
{
    if (!_overView) {
        _overView = [[XYLScanView alloc]initWithFrame:[UIScreen mainScreen].bounds lineMode:XYLScaningLineModeDeafult ineMoveMode:XYLScaningLineMoveModeUpAndDown];
        _overView.delegate = self;
        [self.view insertSubview:_overView atIndex:1];
    }
}

- (void)view:(UIView *)view didCatchGesture:(UIGestureRecognizer *)gesture{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"ViewWillDisappearNotification" object:nil];
    if (self.navigationController) { //如果继续隐藏导航栏 注掉此代码即可
        self.navigationController.navigationBarHidden = NO;
    }
}

//设置导航条模式
- (void)initUI{
    
    if (self.navigationController) {
        if (!self.navigationController.navigationBarHidden) {
            self.navigationController.navigationBarHidden = NavigationBarHidden;
        }
    }
}

- (void)addGesture{
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
    [self.view addGestureRecognizer:pan];
}

- (void)pan:(UIPanGestureRecognizer *)pan{}

//设置扫描反馈模式：这里是声音提示
- (void)config{
    _tone = XYLScaningWarningToneSound;
}


- (void)initCapture
{
    //创建捕捉会话
    session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [session setSessionPreset:AVCaptureSessionPresetHigh];

    //获取摄像设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in devices) {
        if (camera.position == AVCaptureDevicePositionFront) {
            frontCamera = camera;
        }else{
            backCamera = camera;
        }
    }
    //创建输入流
    input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:nil];
    
    //输出流
    output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //添加输入设备(数据从摄像头输入)
    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    //添加输出数据
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    //设置设置输入元数据的类型(如下设置条形码和二维码兼容)
    output.metadataObjectTypes = @[AVMetadataObjectTypeEAN13Code,
                                   AVMetadataObjectTypeEAN8Code,
                                   AVMetadataObjectTypeCode128Code,
                                   AVMetadataObjectTypeQRCode];

    //添加扫描图层
    previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:previewLayer atIndex:0];
    
    //开始捕获
    [session startRunning];
    
    
    CGFloat screenHeight = ScreenSize.height;
    CGFloat screenWidth = ScreenSize.width;
    CGRect cropRect = CGRectMake((screenWidth - TransparentArea([_overView width], [_overView height]).width) / 2,
                                 (screenHeight - TransparentArea([_overView width], [_overView height]).height) / 2,
                                 TransparentArea([_overView width], [_overView height]).width,
                                 TransparentArea([_overView width], [_overView height]).height);
    //设置扫描区域
    [output setRectOfInterest:CGRectMake(cropRect.origin.y / screenHeight,
                                         cropRect.origin.x / screenWidth,
                                         cropRect.size.height / screenHeight,
                                         cropRect.size.width / screenWidth)];
    
}

/**
 * 获取扫描数据
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *stringValue;
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *metadateObject = [metadataObjects objectAtIndex:0];
        stringValue = metadateObject.stringValue;
        [self readingFinshedWithMessage:stringValue];
        [previewLayer removeFromSuperlayer];
    }
}

/**
 *  读取扫描结果
 */
- (void)readingFinshedWithMessage:(NSString *)msg
{
    if (msg) {
        [session stopRunning];
        [self saveInformation:msg];
        [self playSystemSoundWithStyle:_tone];
        
        [self.overView stopMove];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"扫描出来结果%@",msg);
            //todo：在这里添加扫描结果后的处理
            [self.overView removeFromSuperview];
            self.overView = nil;
            [self payCodeSelected];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"读取失败" preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"点击了确定");
        }]];
        [self presentViewController:alert animated:true completion:nil];
    }
}

- (void)saveInformation:(NSString *)strValue{
    
    NSMutableArray *history = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:@"history"]];
    NSDictionary *dic = [NSDictionary dictionaryWithObjects:@[strValue, [self getSystemTime]] forKeys:@[@"value",@"time"]];
    if (!history)
    {
        history = [NSMutableArray array];
    }
    [history addObject:dic];
    [[NSUserDefaults standardUserDefaults]setObject:history forKey:@"history"];
}

- (NSString *)getSystemTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    return [formatter stringFromDate:[NSDate date]];
}

/**
 *  展示声音提示
 */
- (void)playSystemSoundWithStyle:(XYLScaningWarningTone)tone{
    
    NSString *path = [NSString stringWithFormat:@"%@/scan.wav", [[NSBundle mainBundle] resourcePath]];
    SystemSoundID soundID;
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(filePath), &soundID);
    switch (tone) {
        case XYLScaningWarningToneSound:
            AudioServicesPlaySystemSound(soundID);
            break;
        case XYLScaningWarningToneVibrate:
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            break;
        case XYLScaningWarningToneSoundAndVibrate:
            AudioServicesPlaySystemSound(soundID);
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            break;
        default:
            break;
    }
}


@end
