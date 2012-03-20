//
//  sharedMethods.m
//
//  Created by Cassio Rossi on 21/01/09.
//  Copyright 2010 Kazzio Software. All rights reserved.
//

#import <ifaddrs.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <CommonCrypto/CommonDigest.h>

static id sharedInstance;

@implementation sharedMethods

#pragma mark - Singleton Methods

+ (id)shared {
	if (sharedInstance == nil) {
		sharedInstance = [[sharedMethods alloc] init];
	}
	return sharedInstance;
}

#pragma mark - Memory Management

- (void)dealloc {
	[sharedInstance release];
	[super dealloc];
}

#pragma mark - File Methods

- (NSString *)documentDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *docDir = [[paths objectAtIndex:0] stringByAppendingFormat:@"/"];
	paths = nil;
	return docDir;
}

- (NSString *)getFilename:(NSString *)file {
	NSString *filename = [[self documentDirectory] stringByAppendingPathComponent:file];
	return filename;
}

- (void)saveFile:(NSString *)file withData:(NSData *)data appendContent:(BOOL)append {
	if (append) {
		NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:[self getFilename:file]];
		[myHandle seekToEndOfFile];
		[myHandle writeData:data];
		myHandle = nil;
	} else {
		[data writeToFile:[self getFilename:file] atomically:NO];
	}
}

- (NSData *)loadFile:(NSString *)file fromServer:(BOOL)fromServer {
	NSData *returnValue = nil;
	NSString *documentFilename = [self getFilename:file];
	NSString *bundleFilename = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:file];
	id object = nil;

	if (fromServer) {
		NSString *url = [NSString stringWithFormat:@"%@%@", [self checkLocationOfFile], file];
		object = (id)[NSArray arrayWithContentsOfURL:[NSURL URLWithString:url]];
		if ([object count] == 0 || object == nil) {
			object = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:url]];
		}
		url = nil;
	}

	// Se houver erro, pegar os dados localmente (bundle)
	// Save file from bundle to /Documents
	if (object == nil && ![[NSFileManager defaultManager] fileExistsAtPath:documentFilename]) {
		object = (id)[NSArray arrayWithContentsOfFile:bundleFilename];
		if ([object count] == 0 || object == nil) {
			object = [NSDictionary dictionaryWithContentsOfFile:bundleFilename];
		}
	} else if (object == nil) {
		returnValue = [NSData dataWithContentsOfFile:documentFilename];
	}

	if (returnValue == nil && [object count] > 0) {
		if (![[NSKeyedArchiver archivedDataWithRootObject:object] writeToFile:documentFilename atomically:NO]) {
			// Erro na gravacao
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[self getBundleParameter:kCFBundleNameKey]
															 message:NSLocalizedString(@"ERR_FILESAVE_KEY", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"CLOSE_KEY", @"")
												   otherButtonTitles:nil] autorelease];
			[alert show];
			alert = nil;
		} else {
			returnValue = [NSData dataWithContentsOfFile:documentFilename];
		}
	}
	object = nil;
	documentFilename = nil;
	bundleFilename = nil;

	return returnValue;
}

- (NSString *)checkLocationOfFile {
#ifdef LOCALSERVER
	if (!LOCALSERVER)	return MYURL;
	
	//en0 para DEVICE e en1 para SIMULATOR
	NSString *interface = @"en0";
#if TARGET_IPHONE_SIMULATOR
	interface = @"en1";
#endif	
	
	NSArray *ip = [[[self getIPAddress] objectForKey:interface] componentsSeparatedByString:@"."];
	NSString *localIP = [NSString stringWithFormat:@"%@.%@.%@.%@", [ip objectAtIndex:0], [ip objectAtIndex:1], [ip objectAtIndex:2], MYHOSTIP];
	ip = nil; interface = nil;
	
	return [NSString stringWithFormat:@"%@%@%@", MYPROTOCOL, localIP, MYPATH];
#else
	return MYURL;
#endif
}

- (NSString *)checkLocationOfDomain {
#ifdef LOCALSERVER
	if (!LOCALSERVER)	return MYDOMAIN;

	//en0 para DEVICE e en1 para SIMULATOR
	NSString *interface = @"en0";
#if TARGET_IPHONE_SIMULATOR
	interface = @"en1";
#endif	
	
	NSArray *ip = [[[self getIPAddress] objectForKey:interface] componentsSeparatedByString:@"."];
	NSString *localIP = [NSString stringWithFormat:@"%@.%@.%@.%@", [ip objectAtIndex:0], [ip objectAtIndex:1], [ip objectAtIndex:2], MYHOSTIP];
	ip = nil; interface = nil;
	
	return localIP;
#else
	return MYDOMAIN;
#endif
}

- (NSDictionary *)getIPAddress {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	struct ifaddrs *addrs;
	BOOL success = (getifaddrs(&addrs) == 0);
	if (success) {
		const struct ifaddrs *cursor = addrs;
		while (cursor != NULL) {
			NSMutableString *ip;
			if (cursor->ifa_addr->sa_family == AF_INET) {
				const struct sockaddr_in *dlAddr = (const struct sockaddr_in *)cursor->ifa_addr;
				const uint8_t *base = (const uint8_t *)&dlAddr->sin_addr;
				ip = [[NSMutableString new] autorelease];
				for (int i = 0; i < 4; i++) {
					if (i != 0) 
						[ip appendFormat:@"."];
					[ip appendFormat:@"%d", base[i]];
				}
				[result setObject:(NSString *)ip forKey:[NSString stringWithFormat:@"%s", cursor->ifa_name]];
			}
			cursor = cursor->ifa_next;
		}
		freeifaddrs(addrs);
	}
	[pool release];

	return result;
}

#pragma mark - Other Methods

- (NSString *)getBundleParameter:(const CFStringRef)param {
	CFStringRef appName = (CFStringRef)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle() , param);
	CFRetain(appName);
	NSString *returnValue = (NSString *)appName;
	CFRelease(appName);
	return returnValue;
}

- (NSString *)formattedStringFromDate:(NSDate *)date {
	NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"pt_BR"] autorelease]];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *formattedString = [dateFormatter stringFromDate:date];
	[dateFormatter release]; dateFormatter = nil;
	return formattedString;
}

- (NSDate *)dateFromFormattedString:(NSString *)string {
	NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"pt_BR"] autorelease]];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSDate *date = [dateFormatter dateFromString:string];
	[dateFormatter release]; dateFormatter = nil;
	return date;
}

- (NSString *)formattedStringFromDate:(NSDate *)date usingFormat:(NSString *)format {
	NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"pt_BR"] autorelease]];
	[dateFormatter setDateFormat:format];
	NSString *formattedString = [dateFormatter stringFromDate:date];
	[dateFormatter release]; dateFormatter = nil;

	return formattedString;
}

- (NSDate *)dateFromFormattedString:(NSString *)string usingFormat:(NSString *)format {
	NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"us"] autorelease]];
	[dateFormatter setDateFormat:format];
	NSDate *date = [dateFormatter dateFromString:string];
	[dateFormatter release]; dateFormatter = nil;
	return date;
}

- (NSString *)formattedStringFromString:(NSString *)string withFormat:(NSString *)format andDisplayFormat:(NSString *)displayFormat {
	NSDate *myDate = [self dateFromFormattedString:string usingFormat:format];
	NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"pt_BR"] autorelease]];
	[dateFormatter setDateFormat:displayFormat];
	NSString *formattedString = [dateFormatter stringFromDate:myDate];
	[dateFormatter release]; dateFormatter = nil; myDate = nil;
	
	return formattedString;
}

- (NSString *)currencyFormat:(NSString *)value usingSymbol:(NSString *)symbol andDigits:(NSUInteger)digits {
	if ([value isEqualToString:@""] || value == nil) {
		return value;
	}
	
	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"pt_BR"] autorelease]];
	[numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
	[numberFormatter setCurrencySymbol:symbol];
	[numberFormatter setMaximumFractionDigits:digits];
	[numberFormatter setMinimumFractionDigits:digits];
	[numberFormatter setNegativeFormat:[NSString stringWithFormat:@"%@ -", symbol]];
	NSString *formattedValue = [numberFormatter stringFromNumber:(NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:value]];
	numberFormatter = nil;

	return formattedValue;
}

- (NSString *)percentFormat:(NSString *)value andDigits:(NSUInteger)digits {
	if ([value isEqualToString:@""] || value == nil || [value isEqualToString:@"(null)"]) {
		value = @"0";
	}

	NSDecimalNumber *valor = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:value];
	if ([valor floatValue] < 0.0f) {
		//valor = [valor decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithInteger:-1]];
	}

	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"pt_BR"] autorelease]];
	[numberFormatter setNumberStyle: NSNumberFormatterPercentStyle];
	[numberFormatter setMaximumFractionDigits:digits];
	[numberFormatter setMinimumFractionDigits:digits];
	[numberFormatter setNegativePrefix:@"("];
	[numberFormatter setNegativeSuffix:@"%)"];
	NSString *formattedValue = [numberFormatter stringFromNumber:[valor decimalNumberByDividingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithFloat:100.0f]]];
	
	valor = nil; numberFormatter = nil;

	return formattedValue;
}

#pragma mark - Color Management

- (UIColor *)colorWithHexString:(NSString *)stringToConvert {
	NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
	// String should be 6 or 8 characters
	if ([cString length] < 6) return [UIColor blackColor];
	// strip 0X if it appears
	if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
	if ([cString length] != 6) return [UIColor blackColor];
	// Separate into r, g, b substrings
	NSRange range;
	range.location = 0;
	range.length = 2;
	NSString *rString = [cString substringWithRange:range];
	range.location = 2;
	NSString *gString = [cString substringWithRange:range];
	range.location = 4;
	NSString *bString = [cString substringWithRange:range];
	// Scan values
	unsigned int r, g, b;
	[[NSScanner scannerWithString:rString] scanHexInt:&r];
	[[NSScanner scannerWithString:gString] scanHexInt:&g];
	[[NSScanner scannerWithString:bString] scanHexInt:&b];

	bString = nil; gString = nil; rString = nil; cString = nil;

	return [UIColor colorWithRed:rgbColor(r) green:rgbColor(g) blue:rgbColor(b) alpha:1.0f];
}

- (void)setBackgroundColorForView:(UIView *)view using:(NSDictionary *)colorDictionary {
	if (![[colorDictionary objectForKey:@"COR"] isEqualToString:@""]) {
		// Tratamento por cor
		[view setBackgroundColor:[self colorWithHexString:[colorDictionary objectForKey:@"COR"]]];
	} else {
		if (![[colorDictionary objectForKey:@"IMAGEM"] isEqualToString:@""]) {
			[view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:[colorDictionary objectForKey:@"IMAGEM"]]]];
		}
	}
}

#pragma mark - Alert View methods

// Resultado do AlertView - se sim, apagar todo o conteudo da base de dados
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	exit(0);
}

#pragma mark - Text methods

- (CGSize)viewSizeForText:(NSString *)text usingFont:(UIFont *)font {
	return [text sizeWithFont:font constrainedToSize:CGSizeMake(320, 9999) lineBreakMode:UILineBreakModeWordWrap];
}

#pragma mark - UDID Methods

- (NSString *)generateUUID {
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);

	NSString *myUUID = [(NSString *)string stringByReplacingOccurrencesOfString:@"-" withString:@""];
	myUUID = [myUUID stringByAppendingString:[self getMyUDID]];

	const char *cstr = [myUUID cStringUsingEncoding:NSUTF8StringEncoding];
	NSData *data = [NSData dataWithBytes:cstr length:myUUID.length];
	uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(data.bytes, data.length, digest);
	
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];	
	for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x", digest[i]];

	myUUID = [NSString stringWithString:output];
	output = nil;

	return myUUID;
}

- (NSString *)getMyUDID {
	return [[UIDevice currentDevice].uniqueIdentifier stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

@end
