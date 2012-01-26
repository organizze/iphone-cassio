//
//  sharedMethods.h
//
//  Created by Cassio Rossi on 21/01/09.
//  Copyright 2010 Kazzio Software. All rights reserved.
//

// Opcoes para a NavigationBar (lado direito)
#define SHOW_SPIN				0
#define SHOW_RIGHTBUTTON		1
#define SHOW_NOTHING			2
#define HIDE_RIGHTBUTTON		3
#define SHOW_LEFTBUTTON			4
#define HIDE_LEFTBUTTON			5
#define SHOW_EDITING			6

#define degreesToRadian(x) (M_PI * (x) / 180.0)
#define rgbColor(x) ((float)(x)/(float)255)
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:rgbColor((rgbValue & 0xFF0000) >> 16) green:rgbColor((rgbValue & 0xFF00) >> 8) blue:rgbColor(rgbValue & 0xFF) alpha:1.0]

@interface sharedMethods : NSObject <UIAlertViewDelegate> {
}

+ (id)shared;

- (NSString *)getBundleParameter:(const CFStringRef)param;
- (NSString *)documentDirectory;
- (NSString *)getFilename:(NSString *)file;
- (NSData *)loadFile:(NSString *)file fromServer:(BOOL)fromServer;
- (void)saveFile:(NSString *)file withData:(NSData *)data appendContent:(BOOL)append;
- (NSString *)checkLocationOfFile;
- (NSString *)checkLocationOfDomain;
- (NSDictionary *)getIPAddress;
- (NSString *)formattedStringFromDate:(NSDate *)date;
- (NSDate *)dateFromFormattedString:(NSString *)string;
- (NSString *)formattedStringFromDate:(NSDate *)date usingFormat:(NSString *)format;
- (NSDate *)dateFromFormattedString:(NSString *)string usingFormat:(NSString *)format;
- (NSString *)formattedStringFromString:(NSString *)string withFormat:(NSString *)format andDisplayFormat:(NSString *)displayFormat;
- (NSString *)currencyFormat:(NSString *)value usingSymbol:(NSString *)symbol andDigits:(NSUInteger)digits;
- (NSString *)percentFormat:(NSString *)value andDigits:(NSUInteger)digits;
- (UIColor *)colorWithHexString:(NSString *)stringToConvert;
- (void)setBackgroundColorForView:(UIView *)view using:(NSDictionary *)colorDictionary;
- (CGSize)viewSizeForText:(NSString *)text usingFont:(UIFont *)font;
- (NSString *)generateUUID;
- (NSString *)getMyUDID;

@end
