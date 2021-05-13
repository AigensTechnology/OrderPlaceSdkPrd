//
//  MyAlertViewController.m
//  alert
//
//  Created by 陈培爵 on 2018/5/23.
//  Copyright © 2018年 PeiJueChen. All rights reserved.
//  width 270 height 40

#import "MyAlertViewController.h"

#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
@interface MyAlertViewController () {
    BOOL _backgroundCanDismiss;
}
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitle;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerViewConstraint;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *okButtonWidth;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet UIView *verticalLine;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subtitleTop;

@end

@implementation MyAlertViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5];
    _backgroundCanDismiss = true;
    
//    CGFloat statusHeight = SCREEN_HEIGHT == 812 ? 88: 64;
//    NSLog(@"%lf,434234%lf",SCREEN_HEIGHT,statusHeight*0.5);
//    self.containerViewConstraint.constant = statusHeight * 0.5;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configurationParameters: (NSDictionary *)parameters with:(clickOKBlock) okAction {
    
    if ([parameters valueForKey:@"lang"]) {
        NSString *lang = [parameters valueForKey:@"lang"];
        NSString *cancelT = [lang containsString:@"en"] ? @"Cancel" : @"取消";
        NSString *OKT = [lang containsString:@"en"] ? @"Confirm" : @"確定";
        if ([parameters valueForKey:@"okText"]) {
            OKT = [parameters valueForKey:@"okText"];
        }
        if ([parameters valueForKey:@"cancelText"]) {
            cancelT = [parameters valueForKey:@"cancelText"];
        }

        [self.cancelButton setTitle:cancelT forState:normal];
        [self.confirmButton setTitle:OKT forState:normal];
    }
    
    if ([parameters valueForKey:@"themeColor"]) {
        UIColor *themeColor = [self colorWithHexString:[parameters valueForKey:@"themeColor"]];
        self.containerView.backgroundColor = themeColor;
    }
    
    if ([[parameters valueForKey:@"onlyOKButton"] boolValue]) {
        [self.cancelButton setHidden:true];
        [self.verticalLine setHidden:true];
        self.okButtonWidth.constant = 270.0;
//        self.okButtonWidth.constant = self.containerView.bounds.size.width;
    }
    
    if ([parameters valueForKey:@"titleLabel"]) {
        self.titleLabel.text = [parameters valueForKey:@"titleLabel"];
    } else {
        [self.titleLabel removeFromSuperview];
    }
    
    if ([parameters valueForKey:@"subtitleLabel"]) {
        self.subtitle.text = [parameters valueForKey:@"subtitleLabel"];
    }
    
    _backgroundCanDismiss = [parameters valueForKey:@"backgroundCanDismiss"] != NULL ? [[parameters valueForKey:@"backgroundCanDismiss"] boolValue] : true;
    
    if (okAction) {
        self.okAction = okAction;
    }
    
//    [self.view setNeedsLayout];
//    [self.view setNeedsDisplay];
    
    
}
- (IBAction)cancel:(UIButton *)sender {
    [self dismissViewControllerAnimated:false completion:nil];
}
- (IBAction)okAction:(UIButton *)sender {
    
    [self dismissViewControllerAnimated:false completion:^{
        if (self.okAction != nil) {
            self.okAction();
        };
    }];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self.view];
    
    point = [self.containerView.layer convertPoint:point fromLayer:self.view.layer]; //get layer using containsPoint:
    if (![self.containerView.layer containsPoint:point]) {
        if (_backgroundCanDismiss) [self dismissViewControllerAnimated:false completion:nil];
    }

}

- (UIColor *)colorWithHexString:(NSString *)stringToConvert
{
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    
    if ([cString length] < 6)
        return [UIColor whiteColor];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor whiteColor];
    
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}


//- (float)getContactHeight:(NSString*)contact with: (UILabel*)lable;
//{
//    NSDictionary *attrs = @{NSFontAttributeName : lable.font};
//    CGSize maxSize = CGSizeMake(230.0, MAXFLOAT);
//    CGSize size = [contact boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
//    
//    return size.height;
//    
//}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
