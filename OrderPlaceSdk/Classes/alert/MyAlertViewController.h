//
//  MyAlertViewController.h
//  alert
//
//  Created by 陈培爵 on 2018/5/23.
//  Copyright © 2018年 PeiJueChen. All rights reserved.
//

#import <UIKit/UIKit.h>
 typedef void(^clickOKBlock)(void);
@interface MyAlertViewController : UIViewController
@property (nonatomic,copy)clickOKBlock okAction;
/***
 * use:
 * MyAlertViewController * alertController = [[MyAlertViewController alloc] initWithNibName:@"MyAlertViewController" bundle:nil];
 * alertController.providesPresentationContextTransitionStyle = YES;
 * alertController.definesPresentationContext = YES;
 * [alertController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
 * [self presentViewController:alertController animated:false completion:nil];
 *
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

/***
 * parameters :
 * themeColor: string? default: white
 * onlyOKButton: bool? default: false
 * okText : string?
 * cancelText test: stirng?
 * titleLabel: string? default: null 
 * subtitleLabel: string => require
 * lang: string =>require
 * backgroundCanDismiss : bool? => default : true
 */

- (void)configurationParameters: (NSDictionary *)parameters with:(clickOKBlock) okAction;
@end
