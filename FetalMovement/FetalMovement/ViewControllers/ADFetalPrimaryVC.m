//
//  ADFetalPrimaryVC.m
//  FetalMovement
//
//  Created by wangpeng on 14-3-2.
//  Copyright (c) 2014年 wang peng. All rights reserved.
//

#import "ADFetalPrimaryVC.h"
#import "ADSecondVC.h"
#import "NSDate+DateHelper.h"
#import "ADFetalMovementManager.h"
#import "ADTypicalRecordModel.h"
#import "ADTypitalRecordCell.h"
#import "UILabel+CustomeLabel.h"
#import "ADSortModel.h"
#import "ADMilestoneVC.h"
#import "ADScrollCalendar.h"
 #import "ADLoginVC.h"


#import "ADShareView.h"
#import "ADMomInvitedVC.h"
#import "ADExplanationView.h"
#import "CAKeyframeAnimation+GLPadShake.h"

#define recommendButton_tag (10001)
#define jumpButton_tag (20001)
#define jumpButton_height (45)

#define guideImage_tag (40001)
#define handImage_tag (50001)

#define kScrollCalendarAnimationDurarion 0.3f
@interface ADFetalPrimaryVC ()
{
    NSTimeInterval seconds1970;
    BOOL isSelectingDate;
    
    
}
@property (nonatomic, strong)UIScrollView * bg_scrollView;

@property (strong, nonatomic)UIImageView *cloadImageView;
//line
@property (strong, nonatomic) NSMutableArray *ArrayOfValues;//绘制曲线y值
@property (strong, nonatomic) NSMutableArray *ArrayOfDates;//绘制曲线横坐标

//
@property(nonatomic,strong)UILabel *todayCountLabel;
@property(nonatomic,strong)UILabel *todayContentLabel;
@property(nonatomic,strong)UILabel *totalPredicationLabel;
@property(nonatomic,strong)UILabel *hourlyPredicationLabel;
//tabelView dataArray
@property (strong, nonatomic) NSMutableArray *dataArray;

//
@property (strong, nonatomic) UIButton *triangleButton;

//scroll calendar
@property (strong, nonatomic)ADScrollCalendar *calendarScroll;
@end

@implementation ADFetalPrimaryVC
@synthesize bg_scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        //NotificationCenter
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completeRecord:) name:EndRecordFetalMovementNotification object:nil];
    }
    return self;
}
#pragma mark - Notification event
- (void)completeRecord:(NSNotification *)notification
{
    [self updateUI];
}
#pragma mark - 更新页面数据
//可用来更新页面数据
- (void)viewWillAppear:(BOOL)animated{
    
    [self updateUI];
    
}
- (void)viewDidDisappear:(BOOL)animated
{
    [self removeScrollCalendarView];
}
//invoke the method  update UI when need to refresh the view
- (void)updateUI
{
    seconds1970 = [[NSDate localdate] timeIntervalSince1970];
    
    //导航栏上日期显示
    NSString *dateSring = [NSDate stringFromDate:[NSDate localdate] withFormat:@"yyyy.MM.dd"];
    self.navigationView.titleLabel.text = dateSring;
    
    //显示的数字需要更新
    int count1 = [[ADFetalMovementManager sharedADFetalMovementManager] getTotalCountByDate:seconds1970];
    int count2 = [[ADFetalMovementManager sharedADFetalMovementManager] getPredictDailyCountByDate:seconds1970];
    int count3 = [[ADFetalMovementManager sharedADFetalMovementManager] getPredictHourlyCountByDate:seconds1970];
    _todayCountLabel.text = [NSString stringWithFormat:@"%d",count1];
    _totalPredicationLabel.text = [NSString stringWithFormat:@"%d",count2];
    _hourlyPredicationLabel.text = [NSString stringWithFormat:@"%d",count3];
    
    
    //更新曲线图数据
    self.ArrayOfValues.array = [[ADFetalMovementManager sharedADFetalMovementManager] getHourlyStatDataByDate:seconds1970];
    self.ArrayOfDates.array  = [[ADFetalMovementManager sharedADFetalMovementManager] getTwentyfourHours];
    
    [self.lineGraph reloadGraph];
    
    //更新列表数据
    self.dataArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *array = [[ADFetalMovementManager sharedADFetalMovementManager] getTypicalRecordByDate:seconds1970];
    for (int i = 0; i < [array count]; i++) {
        NSDictionary *dic = [array objectAtIndex:i];
        ADTypicalRecordModel *model = [[ADTypicalRecordModel alloc] initWithDictionary:dic order:(i+1)];
        [self.dataArray addObject:model];
    }
    [self.tableView reloadData];
    [self dismissAction];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    seconds1970 = [[NSDate localdate] timeIntervalSince1970];
    [self configureNavigationView];
    [self addLineGraphView]; //折线图
    
    NSDate *loacalDate = [NSDate localdate];//判断当计数为零的时候,显示提示页面
    NSTimeInterval seconds = [loacalDate timeIntervalSince1970];
    int count = [[ADFetalMovementManager sharedADFetalMovementManager] getTotalCountByDate:seconds];
    if (count == 0) {
        [self addFetalMovementCountScrollView];
        [self addGuidePage];
        [self delayGuidView];
    }else{
        [self addFetalMovementCountScrollView];
        [self addTypicalRecordView];
    }
   
}

#pragma mark - guide page

- (void)delayGuidView{
    UIImageView * guideImage= [[UIImageView alloc]initWithFrame:CGRectMake(0, bg_scrollView.frame.size.height, 320, 110)];
    [self.view addSubview: guideImage];
    guideImage.tag = guideImage_tag;
    guideImage.image = [UIImage imageNamed:@"AD小屁股提示@2x"];
    
    UIImageView * handImage= [[UIImageView alloc]initWithFrame:CGRectMake(bg_scrollView.frame.size.width, bg_scrollView.frame.size.height- tabbar_height - 110, 320, 110)];
    [self.view addSubview: handImage];
    handImage.tag = handImage_tag;
    handImage.image = [UIImage imageNamed:@"AD小屁股提示-手@2x"];
    
    [self performSelector:@selector(showGuideAction) withObject:self afterDelay:1];
    
    [self performSelector:@selector(showHandAction) withObject:self afterDelay:1.75];
    
    [self performSelector:@selector(dismissAction) withObject:self afterDelay:4];
}

- (void)showGuideAction{
    UIImageView * guideImage = (UIImageView *)[self.view viewWithTag:guideImage_tag];
    CGPoint centerPoint = CGPointMake(160, self.view.frame.size.height - 55- 49);
    CALayer *layer=[guideImage layer];
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:0.750] forKey:kCATransactionAnimationDuration];
    CAAnimation *chase = [CAKeyframeAnimation animationWithKeyPath:@"position" function:BackEaseOut fromPoint:[guideImage center] toPoint:centerPoint];
    [chase setDelegate:self];
    [layer addAnimation:chase forKey:@"position"];
    [CATransaction commit];
    [guideImage setCenter:centerPoint];
}

- (void)showHandAction{
    UIImageView * handImage = (UIImageView *)[self.view viewWithTag:handImage_tag];
    CGPoint centerPoint = CGPointMake(160, self.view.frame.size.height - 55- 49);
    CALayer *layer=[handImage layer];
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:0.750] forKey:kCATransactionAnimationDuration];
    CAAnimation *chase = [CAKeyframeAnimation animationWithKeyPath:@"position" function:BackEaseOut fromPoint:[handImage center] toPoint:centerPoint];
    [chase setDelegate:self];
    [layer addAnimation:chase forKey:@"position"];
    [CATransaction commit];
    [handImage setCenter:centerPoint];
}

CGFloat BackEaseOut(CGFloat p)
{
	CGFloat f = (1 - p);
	return 1 - (f * f * f - f * sin(f * M_PI));
}

- (void)dismissAction{
    UIImageView * guideImage = (UIImageView *)[self.view viewWithTag:guideImage_tag];
    UIImageView * handImage = (UIImageView *)[self.view viewWithTag:handImage_tag];
    
    [UIView animateWithDuration:0.5 animations:^{
        guideImage.frame = CGRectMake(0, self.view.frame.size.height, 320, 110);
        handImage.frame = CGRectMake(0, self.view.frame.size.height, 320, 110);
    }];
}

- (void)viewWillDisappear:(BOOL)animated{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)addGuidePage{
    
    
    UIImageView *guideView = [[UIImageView alloc]initWithFrame:CGRectMake(0, _fetalMovementScrollView.frame.size.height + _fetalMovementScrollView.frame.origin.y, 320, 50)];//添加智能解读
    [bg_scrollView addSubview:guideView];
    guideView.userInteractionEnabled = YES;
    guideView.image = [UIImage imageNamed:@"AD智能计算-标题@2x"];
    
    UIButton *questionButton = [UIButton buttonWithType:UIButtonTypeCustom]; //问号
    questionButton.frame = CGRectMake(SCREEN_WIDTH - 34/2 - 36/2,  40/2, 34/2, 34/2);
    [questionButton setBackgroundImage:[UIImage imageNamed:@"home_question mark_bg@2x"] forState:UIControlStateNormal];
    [questionButton addTarget:self action:@selector(addDataAnalysisView) forControlEvents:UIControlEventTouchUpInside];
    [guideView addSubview:questionButton];
    
    UIImageView *noDataView = [[UIImageView alloc]initWithFrame:CGRectMake(0, guideView.frame.size.height + guideView.frame.origin.y, 320, 122)];
    noDataView.image = [UIImage imageNamed:@"AD无数据说明@2x"];
    [bg_scrollView addSubview:noDataView];
    
    bg_scrollView.contentSize = CGSizeMake(320, noDataView.frame.size.height + noDataView.frame.origin.y + statusBar_height + navItem_height);
    
}

#pragma mark - configure navigationView
- (void)configureNavigationView
{
    [self.navigationView.backButton setBackgroundImage:[UIImage imageNamed:@"historydata_button@2x"] forState:UIControlStateNormal];
    [self.navigationView.backButton setBackgroundImage:[UIImage imageNamed:@"historydata_button_selected@2x"] forState:UIControlStateHighlighted];
    [self.navigationView.backButton setBackgroundImage:[UIImage imageNamed:@"historydata_button_selected@2x"] forState:UIControlStateSelected];
    
    [self.navigationView.rightButton setBackgroundImage:[UIImage imageNamed:@"share_button@2x"] forState:UIControlStateNormal];
    [self.navigationView.rightButton setBackgroundImage:[UIImage imageNamed:@"share_button_selected@2x"] forState:UIControlStateHighlighted];
    [self.navigationView.rightButton setBackgroundImage:[UIImage imageNamed:@"share_button_selected@2x"] forState:UIControlStateSelected];
    
    
    //
    self.navigationView.titleLabel.text = @"2014.3.10";
    self.navigationView.titleLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selecteDate:)];
    [self.navigationView.titleLabel addGestureRecognizer:tap];
    
    self.triangleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _triangleButton.frame = CGRectMake(self.navigationView.titleLabel.frame.origin.x + self.navigationView.titleLabel.frame.size.width - 8, self.navigationView.frame.size.height - 18, 19/2, 11/2);
    [_triangleButton setBackgroundImage:[UIImage imageNamed:@"triangle_button_bg@2x"] forState:UIControlStateNormal];
    
    [self.navigationView addSubview:_triangleButton];
    
}
#pragma mark - navigation button event
- (void)clickLeftButton
{
    NSLog(@"点击里程碑按钮");
    ADMilestoneVC *milestoneVC = [[ADMilestoneVC alloc] initWithNavigationViewWithTitle:@"胎动里程碑"];
    [self.navigationController pushViewController:milestoneVC animated:YES];
}
- (void)clickRightButton
{
    NSLog(@"点击分享按钮");
    [ADShareView createShareView:[UIApplication sharedApplication].keyWindow];
}

- (void)selecteDate:(UITapGestureRecognizer *)tap
{
    if (isSelectingDate) {
        
        
        [self removeScrollCalendarView];
        
        
        
    }else{
        
        [self showScrollCalendarView];
    }
  
}
#pragma mark - 显示滑动日历view
- (void)showScrollCalendarView
{
    self.navigationView.titleLabel.textColor = [UIColor colorWithRed:217/255.0 green:0/255.0 blue:66/255.0 alpha:0.6];
    [self.triangleButton setBackgroundImage:[UIImage imageNamed:@"triangle_button_selected_bg@2x"] forState:UIControlStateNormal];

    //
    int yAxias = 0;
    if (IOS7_OR_LATER) {
        yAxias = 20;
    }
    self.calendarScroll = [[ADScrollCalendar alloc] initWithFrame:CGRectMake(0, -100, SCREEN_WIDTH, 100)];
    _calendarScroll.backgroundColor = [UIColor colorWithRed:217/255.0 green:0/255.0 blue:66/255.0 alpha:0.6];
    _calendarScroll.alpha = 0;
    //block 回调
    
    __block double seconds;
    __weak ADFetalPrimaryVC *primeVC  = self;
    _calendarScroll.chooseDateBlock = ^(NSDate *date){
        
        NSDate *loacalDate = [NSDate localdateByDate:date];
        seconds = [loacalDate timeIntervalSince1970];
        
        //update graph
        primeVC.ArrayOfValues.array = [[ADFetalMovementManager sharedADFetalMovementManager] getHourlyStatDataByDate:seconds];
        primeVC.ArrayOfDates.array  = [[ADFetalMovementManager sharedADFetalMovementManager] getTwentyfourHours];
        [primeVC.lineGraph reloadGraph];
       
        //update datelabel text
        NSString *dateSring = [NSDate stringFromDate:loacalDate withFormat:@"yyyy.MM.dd"];
        primeVC.navigationView.titleLabel.text = dateSring;
        //remove calendar
        [primeVC removeScrollCalendarView];
        
    };
    
    [self.view addSubview:_calendarScroll];
    [self.view bringSubviewToFront:self.navigationView];
    //[self.view insertSubview:_calendarScroll belowSubview:self.navigationView];

    [UIView animateWithDuration:kScrollCalendarAnimationDurarion animations:^{
        _calendarScroll.alpha = 1.0;
        _calendarScroll.frame = CGRectMake(0, 90/2 + yAxias, SCREEN_WIDTH, 100);

    } completion:^(BOOL finished) {
        
          }];

//    [UIView animateWithDuration:0.1 animations:^{
//        _calendarScroll.frame = CGRectMake(0, 90/2 + yAxias, SCREEN_WIDTH, 100);
//    }];
        isSelectingDate = YES;

    
}
//移除日历选择View
- (void)removeScrollCalendarView
{
    if (_calendarScroll) {
        
        
        [UIView animateWithDuration:kScrollCalendarAnimationDurarion animations:^{
            _calendarScroll.alpha = 0;
            _calendarScroll.frame = CGRectMake(0, -100, SCREEN_WIDTH, 100);
            
        } completion:^(BOOL finished) {
            [_calendarScroll removeFromSuperview];
        }];
  
        
    }
    
    self.navigationView.titleLabel.textColor = [UIColor whiteColor];
    [self.triangleButton setBackgroundImage:[UIImage imageNamed:@"triangle_button_bg@2x"] forState:UIControlStateNormal];
    isSelectingDate = NO;
    
}

#pragma mark - line graph
- (void)addLineGraphView
{
    //添加背景scrollView
    bg_scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, statusBar_height + navItem_height, self.view.frame.size.width, self.view.frame.size.height - (statusBar_height + navItem_height))];
    [self.view addSubview:bg_scrollView];
    bg_scrollView.backgroundColor = UIColorFromRGB(0xFBF7F1);
    
    //line datas
    self.ArrayOfValues = [[NSMutableArray alloc] init];
    self.ArrayOfDates = [[NSMutableArray alloc] init];
    
    
    self.ArrayOfValues.array = [[ADFetalMovementManager sharedADFetalMovementManager] getHourlyStatDataByDate:seconds1970];
    self.ArrayOfDates.array  = [[ADFetalMovementManager sharedADFetalMovementManager] getTwentyfourHours];
    
    NSLog(@"hahhahahaha%@", self.ArrayOfValues);
    
    int yAxias = 0;
    if (IOS7_OR_LATER) {
        yAxias = 20;
    }
    self.cloadImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, SCREEN_WIDTH, 316/2)];
    
    _cloadImageView.backgroundColor = [UIColor colorWithRed:255/255.0 green:118/255.0 blue:133/255.0 alpha:1.0];
    _cloadImageView.image = [UIImage imageNamed:@"cload_bg@2x"];
    _cloadImageView.userInteractionEnabled = YES;
    [bg_scrollView addSubview:_cloadImageView];
    
    self.graphBackgroundScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, _cloadImageView.frame.size.height - 0)];
    _graphBackgroundScrollView.backgroundColor = [UIColor clearColor];
    _graphBackgroundScrollView.bouncesZoom = NO;
    _graphBackgroundScrollView.showsHorizontalScrollIndicator = NO;
    int yMargin = 0;
    if (IOS7_OR_LATER) {
        yMargin = 80;
    }
    _graphBackgroundScrollView.contentSize = CGSizeMake(640, _graphBackgroundScrollView.frame.size.height - yMargin);
    [_cloadImageView addSubview:_graphBackgroundScrollView];
    
    self.lineGraph = [[ADLineGraphView alloc] initWithFrame:CGRectMake(0,0, 640, _graphBackgroundScrollView.frame.size.height)];
    _lineGraph.delegate = self;
    _lineGraph.backgroundColor = [UIColor clearColor];
    _lineGraph.colorLine = [UIColor whiteColor];
    _lineGraph.colorXaxisLabel = [UIColor whiteColor];
    _lineGraph.widthLine = 1.0;
    _lineGraph.alphaLine = 1.0;
    _lineGraph.animationGraphEntranceSpeed = 5.0;
    [_graphBackgroundScrollView addSubview:_lineGraph];
    
    
    //绘制区域添加Label
    UIButton * recommendButton = [[UIButton alloc]init];
    [bg_scrollView addSubview:recommendButton];
    recommendButton.tag = recommendButton_tag;
    recommendButton.frame = CGRectMake(10, 40, 300, 30);
    recommendButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [recommendButton setTitle:@"与544,224位妈妈一起记录胎动吧!" forState:UIControlStateNormal];

    UIImage * image = [UIImage imageNamed:@"AD一起记胎动按钮小@2x"];//拉伸图片
    UIImage * imageClicked = [UIImage imageNamed:@"AD一起记胎动按钮小-点击@2x"];
    //resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)

    [recommendButton setBackgroundImage:image forState:UIControlStateNormal];
    [recommendButton setBackgroundImage:imageClicked forState:UIControlStateHighlighted];
    [recommendButton addTarget:self action:@selector(recommendAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)recommendAction:(UIButton*)button{//跳转到邀请妈妈页面
    NSLog(@"跳转到邀请妈妈页面");
    ADMomInvitedVC *momInViteVC = [[ADMomInvitedVC alloc]initWithNavigationViewWithTitle:@"邀请更多妈妈"];
    [self.navigationController pushViewController:momInViteVC animated:YES];
}


#pragma mark - SimpleLineGraph Data Source
- (int)numberOfPointsInGraph {
    
    return (int)[self.ArrayOfValues count];
    
}

- (float)valueForIndex:(NSInteger)index {
    
    return [[self.ArrayOfValues objectAtIndex:index] floatValue];
}
//optional delegate method
- (int)numberOfGradesInYAxis
{
    return 12 - 1;
}



#pragma mark - SimpleLineGraph Delegate

- (int)numberOfGapsBetweenLabels {
    return 0;
}

- (NSString *)labelOnXAxisForIndex:(NSInteger)index {
    return [self.ArrayOfDates objectAtIndex:index];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - total fetalCount && Prediction
/**
 *  已记录一天胎动总数  推测一天胎动总和平均每小时胎动
 */
- (void)addFetalMovementCountScrollView
{
    self.fetalMovementScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _cloadImageView.frame.origin.y + _cloadImageView.frame.size.height, SCREEN_WIDTH, 240/2 - 12)];
    _fetalMovementScrollView.backgroundColor = [UIColor whiteColor];
    _fetalMovementScrollView.bouncesZoom = NO;
    _fetalMovementScrollView.pagingEnabled = YES;
    _fetalMovementScrollView.delegate = self;
    _fetalMovementScrollView.showsHorizontalScrollIndicator = NO;
    _fetalMovementScrollView.contentSize = CGSizeMake(SCREEN_WIDTH *2, _fetalMovementScrollView.frame.size.height);
    [bg_scrollView addSubview:_fetalMovementScrollView];
    
    
    UILabel *todayTitle = [UILabel labelWithTitle:@"今日记录胎动总数"
                                            frame:CGRectMake((SCREEN_WIDTH - 200)/2, 30/2, 200, 24/2)
                                        textColor:kOrangeFontColor
                                    textAlignment:NSTextAlignmentCenter
                                             font:kMacroFontSize
                                        superView:_fetalMovementScrollView];
    
    UIButton *questionButton = [UIButton buttonWithType:UIButtonTypeCustom]; //问号
    questionButton.frame = CGRectMake(SCREEN_WIDTH - 34/2 - 36/2, 30/2, 34/2, 34/2);
    [questionButton setBackgroundImage:[UIImage imageNamed:@"home_question mark_bg@2x"] forState:UIControlStateNormal];
    [questionButton addTarget:self action:@selector(addDataAnalysisView) forControlEvents:UIControlEventTouchUpInside];
    [_fetalMovementScrollView addSubview:questionButton];

    
    NSDate *localDate = [NSDate localdate];
    NSTimeInterval seconds = [localDate timeIntervalSince1970];
    int count = [[ADFetalMovementManager sharedADFetalMovementManager] getTotalCountByDate:seconds];
    self.todayCountLabel = [UILabel labelWithTitle:[NSString stringWithFormat:@"%d",count]
                                             frame:CGRectMake((SCREEN_WIDTH - 70)/2, todayTitle.frame.origin.y + todayTitle.frame.size.height + 30/2, 70, 50)
                                         textColor:kRedFontColor
                                     textAlignment:NSTextAlignmentCenter
                                              font:[UIFont systemFontOfSize:120/2]
                                         superView:_fetalMovementScrollView];
    
    
    UILabel *unitLable1 = [UILabel labelWithTitle:@"次"
                                            frame:CGRectMake(_todayCountLabel.frame.origin.x + _todayCountLabel.frame.size.width, _todayCountLabel.frame.origin.y + _todayCountLabel.frame.size.height - 20 , 20, 20)
                                        textColor:kRedFontColor
                                    textAlignment:NSTextAlignmentLeft
                                             font:[UIFont systemFontOfSize:28/2]
                                        superView:_fetalMovementScrollView];
    
    
    
//    self.todayContentLabel = [UILabel labelWithTitle:@"2222222位妈妈记录超过20次"
//                                               frame:CGRectMake((SCREEN_WIDTH - 300)/2, _todayCountLabel.frame.origin.y + _todayCountLabel.frame.size.height + 24/2, 300, 24/2)
//                                           textColor:kRedFontColor
//                                       textAlignment:NSTextAlignmentCenter
//                                                font:kMacroFontSize
//                                           superView:_fetalMovementScrollView];
    
    
    UILabel *totalPredicationTitle = [UILabel labelWithTitle:@"推算今日胎动总数"
                                                       frame:CGRectMake( 320 + 48/2, todayTitle.frame.origin.y, 150, todayTitle.frame.size.height)
                                                   textColor:todayTitle.textColor
                                               textAlignment:NSTextAlignmentLeft
                                                        font:todayTitle.font
                                                   superView:_fetalMovementScrollView];
    
    
    count = [[ADFetalMovementManager sharedADFetalMovementManager] getPredictDailyCountByDate:seconds];
    self.totalPredicationLabel = [UILabel labelWithTitle:[NSString stringWithFormat:@"%d",count]
                                                   frame:CGRectMake(totalPredicationTitle.frame.origin.x, totalPredicationTitle.frame.origin.y + totalPredicationTitle.frame.size.height + 40/2, 70, 50)
                                               textColor:kRedFontColor
                                           textAlignment:NSTextAlignmentCenter
                                                    font:[UIFont systemFontOfSize:120/2]
                                               superView:_fetalMovementScrollView];
    
    
    UILabel *unitLable2 = [UILabel labelWithTitle: @"次"
                                            frame:CGRectMake(_totalPredicationLabel.frame.origin.x + _totalPredicationLabel.frame.size.width, _totalPredicationLabel.frame.origin.y + _totalPredicationLabel.frame.size.height - 20, 20, 20)
                                        textColor:kRedFontColor
                                    textAlignment:NSTextAlignmentLeft
                                             font:[UIFont systemFontOfSize:28/2]
                                        superView:_fetalMovementScrollView];
    
    
    UILabel *hourlyPredicationTitle = [UILabel labelWithTitle:@"推算每小时平均胎动"
                                                        frame:CGRectMake( SCREEN_WIDTH + 356/2, todayTitle.frame.origin.y, 150, todayTitle.frame.size.height)
                                                    textColor:todayTitle.textColor
                                                textAlignment:NSTextAlignmentLeft
                                                         font:todayTitle.font
                                                    superView:_fetalMovementScrollView];
    
    
    count = [[ADFetalMovementManager sharedADFetalMovementManager] getPredictHourlyCountByDate:seconds];
    self.hourlyPredicationLabel = [UILabel labelWithTitle:[NSString stringWithFormat:@"%d",count]
                                                    frame:CGRectMake(hourlyPredicationTitle.frame.origin.x, _totalPredicationLabel.frame.origin.y, 70, 50)
                                                textColor:kRedFontColor
                                            textAlignment:NSTextAlignmentCenter
                                                     font:[UIFont systemFontOfSize:120/2]
                                                superView:_fetalMovementScrollView];
    
    
    
    UILabel *unitLable3 = [UILabel labelWithTitle:@"次/小时"
                                            frame:CGRectMake(_hourlyPredicationLabel.frame.origin.x + _hourlyPredicationLabel.frame.size.width, _hourlyPredicationLabel.frame.origin.y + _hourlyPredicationLabel.frame.size.height - 20, 80, 20)
                                        textColor:kRedFontColor
                                    textAlignment:NSTextAlignmentLeft
                                             font:[UIFont systemFontOfSize:28/2]
                                        superView:_fetalMovementScrollView];
    
    UIButton *jumpButton = [[UIButton alloc]init];
    jumpButton.tag = jumpButton_tag;
    //    jumpButton.backgroundColor = [UIColor redColor];
    [jumpButton setImage:[UIImage imageNamed:@"AD下一页@2x"] forState:UIControlStateNormal];
    [jumpButton addTarget:self action:@selector(jumpAction:) forControlEvents:UIControlEventTouchUpInside];
    jumpButton.frame = CGRectMake(bg_scrollView.frame.size.width-23, _cloadImageView.frame.origin.y + _cloadImageView.frame.size.height + jumpButton_height, 23,45);
    [bg_scrollView addSubview:jumpButton];
    
    
}



- (void)jumpAction:(UIButton *)button {
    if (button.frame.origin.x == 0) {
        [button setImage:[UIImage imageNamed:@"AD下一页@2x"] forState:UIControlStateNormal];
        button.frame = CGRectMake(bg_scrollView.frame.size.width-23, _cloadImageView.frame.origin.y + _cloadImageView.frame.size.height + jumpButton_height, 23,45);
        
        [UIView  animateWithDuration:0.3 animations:^{
            _fetalMovementScrollView.contentOffset = CGPointMake(0, 0);
        }];
    }else{
        [button setImage:[UIImage imageNamed:@"AD上一页@2x"] forState:UIControlStateNormal];
        button.frame = CGRectMake(0, _cloadImageView.frame.origin.y + _cloadImageView.frame.size.height + jumpButton_height, 23,45);
        [UIView  animateWithDuration:0.3 animations:^{
            _fetalMovementScrollView.contentOffset = CGPointMake(SCREEN_WIDTH, 0);
        }];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    //scrollView frame-> (0, _cloadImageView.frame.origin.y + _cloadImageView.frame.size.height, SCREEN_WIDTH, 240/2)];
    UIButton * jumpButton = (UIButton *)[bg_scrollView viewWithTag:jumpButton_tag];
    if (_fetalMovementScrollView.contentOffset.x == 0) {//点击button
        jumpButton.frame = CGRectMake(bg_scrollView.frame.size.width-23, _cloadImageView.frame.origin.y + _cloadImageView.frame.size.height + jumpButton_height, 23,45);
        [jumpButton setImage:[UIImage imageNamed:@"AD下一页@2x"] forState:UIControlStateNormal];
    }
    if (_fetalMovementScrollView.contentOffset.x == SCREEN_WIDTH) {
        jumpButton.frame = CGRectMake(0, _cloadImageView.frame.origin.y + _cloadImageView.frame.size.height + jumpButton_height, 23,45);
        [jumpButton setImage:[UIImage imageNamed:@"AD上一页@2x"] forState:UIControlStateNormal];
        
        
    }
}


#pragma mark - button event
- (void)addDataAnalysisView
{
    //加载数据解读view
    
    [ADExplanationView createShareView:[UIApplication sharedApplication].keyWindow];
    
}
#pragma mark - total fetalCount && Prediction
/**
 *  展示当天典型的三次小时胎动记录
 */
- (void)addTypicalRecordView
{
    //加载tableview
    int kHeight;
    if (RETINA_INCH4) {
        kHeight = 200;
    }else{
        kHeight = 60;
    }
    
    self.tableView = [[UITableView alloc] init];
    _tableView.frame = CGRectMake(0, _fetalMovementScrollView.frame.origin.y + _fetalMovementScrollView.frame.size.height, SCREEN_WIDTH,kHeight);
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _fetalMovementScrollView.frame.origin.y + _fetalMovementScrollView.frame.size.height, SCREEN_WIDTH,kHeight)];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor colorWithRed:251/255.0 green:247/255.0 blue:241/255.0 alpha:1.0];
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [bg_scrollView addSubview:_tableView];
    
    
    self.dataArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *array = [[ADFetalMovementManager sharedADFetalMovementManager] getTypicalRecordByDate:20000];
    for (int i = 0; i < [array count]; i++) {
        NSDictionary *dic = [array objectAtIndex:i];
        ADTypicalRecordModel *model = [[ADTypicalRecordModel alloc] initWithDictionary:dic order:(i+1)];
        [self.dataArray addObject:model];
    }
    
    bg_scrollView.contentSize = CGSizeMake(320, _tableView.frame.size.height + _tableView.frame.origin.y + statusBar_height + navItem_height);
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    // Return the number of sections.
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.dataArray count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellTypicalRecord = @"CellTypicalRecord";
    
    ADTypitalRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:CellTypicalRecord];
    if (cell == nil) {
        cell = [[ADTypitalRecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellTypicalRecord];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    ADTypicalRecordModel *model = [self.dataArray objectAtIndex:indexPath.row];
    cell.recordModel = model;
    
    return cell;
    
    
}
#pragma mark - tabelview delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
}

@end
