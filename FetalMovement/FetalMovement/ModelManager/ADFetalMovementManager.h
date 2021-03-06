//
//  FetalMovementManager.h
//  FetalMovement
//
//  Created by poppy on 14-3-1.
//  Copyright (c) 2014年 wang peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADSingleton.h"//单例宏模板
#import "FetalMovementModel.h"
@interface ADFetalMovementManager : NSObject

//Singleton define
DEFINE_SINGLETON_FOR_CLASS(ADFetalMovementManager)

/**
 *根据日期获取每小时的胎动次数统计，用于曲线展示
 @return [NSString,NSString...],表示数值
 */
- (NSArray *)getHourlyStatDataByDate:(double) timestamp;

/**
 *根据日期获取当天胎动总次数
 */
- (int)getTotalCountByDate:(double) timestamp;

/**
 *根据日期获取当天预测全天胎动总次数
 */
- (int)getPredictDailyCountByDate:(double) timestamp;

/**
 *根据日期获取当天预测小时胎动次数
 */
- (int)getPredictHourlyCountByDate:(double) timestamp;

/**
 *根据日期获取当天典型的三次小时胎动记录
 *@return [{'startTimeStamp':(NSString *), 'endTimeStamp':(NSString *), 'count':(NSString *)}]
 */
- (NSArray *)getTypicalRecordByDate:(double) timestamp;

/**
 *记录胎动
 *@param data 时间戳的数组 [(NSString *), (NSString *), ... , (NSString *)]
 *@throw NSException 保存出现问题抛出异常，上层Controller处理异常
 */
- (void)appendData:(NSArray *) datas;

/**
 *  按格式排列 24小时
 *
 *  @return @["00:00,01:00......."]
 */

- (NSArray *)getTwentyfourHours;
/**
 *  返回时间段之间的胎动数据
 *
 *  @param startTimestamp 开始日期
 *  @param endTimestamp   结束日期
 *
 *  @return [{'date':(NSString *), 'count':(NSString *), 'gestationalWeeks':(NSString *),'medal':(NSString *),'tag':(NSString *),'isSection':(NSString *)}]
 */
- (NSArray *)getMilestonsDataWithStartDate:(double)startTimestamp endDate:(double)endTimestamp;

/**
 *  返回时间段之间的胎动数据
 *
 *  @param startTimestamp 开始日期
 *  @param endTimestamp   结束日期
 *  return JSON格式的数据
 *  @return [{'hour':(NSNumber *), 'data':@"int int int"}...]
 */

- (NSData *)getNeedToSyncDataWithStartDate:(double)startTimestamp endDate:(double)endTimestamp;
@end
