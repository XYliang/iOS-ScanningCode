
<img src="https://github.com/XYliang/GithubImages/blob/master/GithubXYLIcon/GithubXYLIcon.png?raw=true" width = "150" height = "150" alt="图片名称" align=center />
# iOS-ScanningCode
  * Support for generating two-dimensional code, two-dimensional code scanning. 
  * 支持生成二维码，扫描二维码、条形码。
  
##Image Displey(图片展示)
<img src="https://github.com/XYliang/GithubImages/blob/master/iOS-ScanningCode/1.PNG?raw=true" width = "375" height = "667" alt="图片名称" align=center />
<img src="https://github.com/XYliang/GithubImages/blob/master/iOS-ScanningCode/2.PNG?raw=true" width = "375" height = "667" alt="图片名称" align=center />

<img src="https://github.com/XYliang/GithubImages/blob/master/iOS-ScanningCode/4.PNG?raw=true" width = "375" height = "667" alt = "图片名称" align = center />
<img src="https://github.com/XYliang/GithubImages/blob/master/iOS-ScanningCode/5.PNG?raw=true" width = "375" height = "667" alt = "图片名称" align = center />

##Getting Start(开始使用)

```objc
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

```

* 创建并添加生成二维码界面
```objc
//设置生成二维码界面
self.binaryCodeView = [[XYLBinaryCodeView alloc]initWithFrame:[UIScreen mainScreen].bounds];
//设置二维码的内容
self.binaryCodeView.inputData = @"www.baidu.com";
[self.view insertSubview:self.binaryCodeView atIndex:1];
```
* 创建并添加扫描二维码界面

```objc
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
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) 
    {
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
        _overView = [[XYLScanView alloc]initWithFrame:[UIScreen mainScreen].bounds lineMode:XYLScaningLineModeGrid ineMoveMode:XYLScaningLineMoveModeUpAndDown];
        _overView.delegate = self;
        [self.view insertSubview:_overView atIndex:1];
    }
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
```
