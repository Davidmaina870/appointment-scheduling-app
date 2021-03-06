//
//  SBBookingFormHoursSelectorDataSource.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 10.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBBookingFormHoursSelectorDataSource.h"
#import "SBWorkingHoursMatrix.h"
#import "NSDate+TimeManipulation.h"
#import "SBDateRange.h"

@interface SBBookingFormHoursSelectorDataSource ()
{
    NSDate *startHour;
    NSDate *endHour;
    BOOL isEndHoursMode;
}

@property (nonatomic, strong, readwrite, nullable) SBWorkingHoursMatrix *workingHoursMatrix;
@property (nonatomic, strong, readwrite, nullable) NSArray *hours;
@property (nonatomic, strong, readwrite, nullable) NSMutableDictionary <NSObject *, NSArray *> *googleBusyHours;

@end

@implementation SBBookingFormHoursSelectorDataSource

- (void)setWorkingHoursMatrix:(SBWorkingHoursMatrix *)matrix recordID:(NSObject *)recordID
{
    NSParameterAssert(recordID != nil);
    self.workingHoursMatrix = matrix;
    self.recordID = recordID;
    if (self.workingHoursMatrix == nil) {
        self.hours = @[];
        return;
    }
    if ([self.workingHoursMatrix isDayOffForRecordWithID:self.recordID]) {
        self.hours = @[];
        return;
    }
    if (self.timeFrameStep == 0) {
        self.timeFrameStep = 60;
    }
    NSDate *hour = [self.workingHoursMatrix startTimeForRecordWithID:self.recordID];
    NSAssert(hour != nil, @"unexpected start time");
    if (hour == nil) {
        self.hours = @[];
        return;
    }
    NSDateComponents *components = [NSDateComponents new];
    components.minute = self.timeFrameStep;
    NSCalendar *calendar = [NSDate sb_calendar];
    NSMutableArray *hours = [NSMutableArray array];
    while ([hour compare:[self.workingHoursMatrix endTimeForRecordWithID:self.recordID]] <= NSOrderedSame) {
        [hours addObject:hour];
        hour = [calendar dateByAddingComponents:components toDate:hour options:0];
    }
    self.hours = hours;
}

- (void)setGoogleBusyHours:(nonnull NSArray <NSDictionary <NSString *, NSDate *> *> *)hours forRecordID:(NSObject <NSCopying> *)recordID
{
    NSParameterAssert(hours != nil);
    NSParameterAssert(recordID != nil);
    if (self.googleBusyHours == nil) {
        self.googleBusyHours = [NSMutableDictionary dictionary];
    }
    NSMutableArray *list = [NSMutableArray array];
    for (NSDictionary <NSString *, NSDate *> *busyHour in hours) {
        [list addObject:[SBDateRange dateRangeWithStart:busyHour[@"from"] end:busyHour[@"to"]]];
    }
    self.googleBusyHours[recordID] = list;
}

- (BOOL)isBreakHour:(NSDate *)hour
{
    __block BOOL isBreakHour = NO;
    [[self.workingHoursMatrix breaksForRecordWithID:self.recordID] enumerateObjectsUsingBlock:^(SBDateRange *obj, NSUInteger idx, BOOL *stop) {
        if ([obj containsDate:hour]) {
            *stop = YES;
            isBreakHour = YES;
        }
    }];
    return isBreakHour;
}

- (BOOL)isGoogleBusyHour:(NSDate *)hour
{
    if (!self.recordID || self.googleBusyHours[self.recordID] == nil) {
        return NO;
    }
    for (SBDateRange *range in self.googleBusyHours[self.recordID]) {
        if ([range containsDate:hour]) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.hours.count;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSAssert(self.workingHoursMatrix != nil, @"Working hours matrix not set.");
    NSAssert(self.timeFormatter != nil, @"Time formatter not set.");
    static NSMutableParagraphStyle *paragraphStyle = nil;
    NSString *hour = [self.timeFormatter stringFromDate:self.hours[row]];
    if (!paragraphStyle) {
        paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentLeft;
    }
    NSMutableAttributedString *attributedString = nil;
    NSString *breakHourMessage = nil;
    if ([self isBreakHour:self.hours[row]]) {
        breakHourMessage = NSLS(@"(not working)", @"add/edit booking form: not working hour in hour selector");
    }
    else if ([self isGoogleBusyHour:self.hours[row]]) {
        breakHourMessage = NSLS(@"(Google Calendar busy)", @"add/edit booking form: not working hour in hour selector");
    }
    
    if (breakHourMessage != nil) {
        NSString *string = [NSString stringWithFormat:@"• %@ %@", hour, breakHourMessage];
        attributedString = [[NSMutableAttributedString alloc] initWithString:string];
        [attributedString addAttributes:@{NSForegroundColorAttributeName : [UIColor grayColor], NSFontAttributeName: [UIFont systemFontOfSize:10]}
                                  range:NSMakeRange(0, attributedString.length)];
        [attributedString addAttributes:@{NSForegroundColorAttributeName : [UIColor grayColor]}
                                  range:NSMakeRange(0, @"•".length)];
        [attributedString addAttributes:@{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]}
                                  range:[string rangeOfString:breakHourMessage]];
    }
    else {
        attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"• %@", hour]];
        [attributedString addAttributes:@{NSForegroundColorAttributeName : [UIColor clearColor]}
                                  range:NSMakeRange(0, @"•".length)];
    }
    [attributedString addAttributes:@{NSParagraphStyleAttributeName : paragraphStyle}
                              range:NSMakeRange(0, attributedString.length)];
    return attributedString;
}

- (void)setStartHoursModeWithStartHour:(NSDate *)_startHour
{
    isEndHoursMode = NO;
    startHour = _startHour;
}

- (void)setEndHoursModeWithEndHour:(NSDate *)_endHour
{
    isEndHoursMode = YES;
    endHour = _endHour;
}

@end
