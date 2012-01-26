//
//  parser.h
//
//  Created by Cassio on 07/09/09.
//  Copyright 2010 Kazzio Software. All rights reserved.
//

#import <libxml/tree.h>
#import "networkMethods.h"

#define DONOTHING				-1
#define OBTERUSERSETTINGS		0
#define OBTERUSERCATEGORIES		1
#define OBTERUSERACCOUNTS		2
#define OBTERTRANSACTIONS		3
#define DOUSERLOGIN				4
#define GETUSERPASSWORD			5
#define DOSYNC					6
#define DOSYNCDONE				7

@protocol parserDelegate <NSObject>
@optional
	- (void)showNoNetworkErrorMessage;
	- (void)showNetworkErrorMessage;
	- (void)showErrorMessage;
	- (void)returnFromParse:(id)parsedObject withData:(NSData *)parsedData;
	- (void)processNetworkActivity;
@end

@interface parser : NSObject <networkMethodsDelegate> {
	id <parserDelegate>	 delegate;
	int					 whatToDo;
	BOOL				 erroXML, isParsing, abortParse, storingCharacters, parsingXMLItem, fileNotFound;

	NSURLConnection		*asyncConnection;
	NSMutableURLRequest *request;
	networkMethods		*net;

	NSMutableData		*responseFromServer, *characterBuffer;
	xmlParserCtxtPtr	 context;

	NSMutableArray		*respostaXML, *extraData;
	NSString			*mensagem;
	NSMutableDictionary	*parsedContent;
}

@property int whatToDo;
@property BOOL storingCharacters, parsingXMLItem, abortParse;

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSURLConnection *asyncConnection;
@property (nonatomic, retain) NSMutableURLRequest *request;
@property (nonatomic, retain) networkMethods *net;
@property (nonatomic, retain) NSMutableData *responseFromServer, *characterBuffer;
@property (nonatomic, retain) NSMutableArray *respostaXML, *extraData;
@property (nonatomic, retain) NSString *mensagem;
@property (nonatomic, retain) NSMutableDictionary *parsedContent;

+ (id)shared;
- (void)destroy;

- (void)abortLibXMLParse;
- (void)parse:(int)whatToParse withParam:(id)param;
- (void)parseData:(NSMutableData *)data;
- (void)didFindAnswer;
- (void)finishedCurrentTAG;
- (NSString *)prepareXMLValue:(NSString *)valor;
- (NSDate *)prepareXMLDate:(NSString *)valor;

- (void)checkNetwork;
- (void)reachabilityChanged:(NSNotification *)notification;
- (void)networkStatusChanged:(BOOL)networkIsAvailable;

@end
