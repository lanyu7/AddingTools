//
//  ADDuedateVC.m
//  FetalMovement
//
//  Created by wangpeng on 14-3-14.
//  Copyright (c) 2014年 wang peng. All rights reserved.
//

#import "ADDuedateVC.h"
#import "BTSheetPickerview.h"

@interface ADDuedateVC ()
@property(nonatomic,strong)UITextField *telNumberField;
@property(nonatomic,strong)BTSheetPickerview *actionSheetView;
@property(nonatomic,strong)UILabel *duedateLabel;
@end

@implementation ADDuedateVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self configureNavigationView];
    
    int navigationHeight = [[ADUIParamManager sharedADUIParamManager] getNavigationBarHeight];
    UIImageView *calendarImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"setting_calendar_bg@2x"]];
    calendarImage.frame = CGRectMake((SCREEN_WIDTH - 210/2)/2, navigationHeight + 24/2, 210/2, 210/2);
    [self.view addSubview:calendarImage];
    
    //电话 或者邮箱
    
    CGRect rect = CGRectMake((320 - 580/2)/2,calendarImage.frame.origin.y + calendarImage.frame.size.height + 24/2,580/2 ,110/2);
    UIImage* bgimg = [UIImage imageNamed:@"register_border_bg@2x"];
    UIImageView*  telbg = [[UIImageView alloc]initWithFrame:rect];
    telbg.image = bgimg;
    telbg.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:telbg];
    
    CGRect rectBut;
    rectBut = rect;
    rectBut.size.width  -=20 * 2;
    rectBut.size.height  = 22;
    rectBut.origin.x    += 20;
    rectBut.origin.y    += (int)( (rect.size.height - rectBut.size.height) /2);
    
    self.telNumberField                      = [[UITextField alloc] init];
    _telNumberField.backgroundColor      = [UIColor whiteColor];
    _telNumberField.keyboardType         = UIKeyboardTypePhonePad;
    _telNumberField.borderStyle          = UITextBorderStyleNone;
    _telNumberField.clipsToBounds        = YES;
    _telNumberField.clearButtonMode      = UITextFieldViewModeWhileEditing;
    _telNumberField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _telNumberField.autocorrectionType   = UITextAutocorrectionTypeNo;
    _telNumberField.placeholder          = @"邮箱地址 或 手机号码";
    _telNumberField.font                 = [UIFont systemFontOfSize:17];
    _telNumberField.frame                = rectBut;
    _telNumberField.delegate             = self;
//    [self.view addSubview:_telNumberField];
    
    self.duedateLabel                  = [[UILabel alloc] init];
    _duedateLabel.backgroundColor      = [UIColor whiteColor];
    _duedateLabel.clipsToBounds        = YES;
    _duedateLabel.font                 = [UIFont systemFontOfSize:17];
    _duedateLabel.frame                = rectBut;
    _duedateLabel.userInteractionEnabled = YES;
    
    _duedateLabel.textAlignment        = NSTextAlignmentCenter;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inputDate:)];
    [_duedateLabel addGestureRecognizer:tap];

    [self.view addSubview:_duedateLabel];

    
    [self showDatePicker];
    
    // Do any additional setup after loading the view.
}
- (void)configureNavigationView
{
    self.navigationView.backgroundColor = [UIColor whiteColor];
    self.navigationView.titleLabel.textColor = kOrangeFontColor;
    
    [self.navigationView.backButton setBackgroundImage:[UIImage imageNamed:@"navigation_backbutton_bg@2x"] forState:UIControlStateNormal];
    //    [self.navigationView.backButton setBackgroundImage:[UIImage imageNamed:@"historydata_button_selected@2x"] forState:UIControlStateHighlighted];
    //    [self.navigationView.backButton setBackgroundImage:[UIImage imageNamed:@"historydata_button_selected@2x"] forState:UIControlStateSelected];
}
#pragma mark - navigation button event
- (void)clickLeftButton
{
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self.actionSheetView hide];
}

#pragma mark - private method
- (void)inputDate:(UITapGestureRecognizer *)tap
{
    [self showDatePicker];
}

- (void)showDatePicker
{
    self.actionSheetView = [[BTSheetPickerview alloc] initWithPikerType:BTActionSheetPickerStyleDatePicker
                                                              referView:nil
                                                               delegate:self
                                                                  title:@"选择预产期日期"];
    
    //确定滚轮日期范围
    NSDate *localDate = [NSDate localdate];
    NSNumber *year = [NSDate getYear:localDate];
    NSDate* minDate =  [NSDate localDateFromString:[NSString stringWithFormat:@"%d.01.01",([year intValue] - 1)] withFormat:@"yyyy.MM.dd"];
    NSDate* maxDate =  [NSDate localDateFromString:[NSString stringWithFormat:@"%d.01.01",([year intValue] + 1)] withFormat:@"yyyy.MM.dd"];
    self.actionSheetView.datePicker.minimumDate = minDate;
    self.actionSheetView.datePicker.maximumDate = maxDate;
    //确定时间选择器默认的时间
    
    self.actionSheetView.datePicker.date = [NSDate localdate];
  
    [_actionSheetView show];
   

}

#pragma mark - 输入预产期 日期选择器delegate
- (void)actionSheetPickerView:(BTSheetPickerview *)pickerView didSelectDate:(NSDate*)date
{
    
    NSDate *localDate = [NSDate localdateByDate:date];
    NSString *dateAndTime = [NSDate stringFromDate:localDate withFormat:@"yyyy - MM - dd"];
    
    //刷新UI
    self.duedateLabel.text = dateAndTime;
    
    //存储数据
    [[ADAccountCenter sharedADAccountCenter] writeDuedateToUserdefalutWithDate:localDate];
}
#pragma mark - 日期边滚动 边触发的方法
- (void)actionSheetPickerView:(BTSheetPickerview *)pickerView didScrollDate:(NSDate*)date
{
    
    NSDate *localDate = [NSDate localdateByDate:date];
    NSString *dateAndTime = [NSDate stringFromDate:localDate withFormat:@"yyyy - MM - dd"];
    
    //刷新UI
    self.duedateLabel.text = dateAndTime;
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end