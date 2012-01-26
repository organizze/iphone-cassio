//
//  parser.m
//
//  Created by Cassio on 07/09/09.
//  Copyright 2010 Kazzio Software. All rights reserved.
//

#include <sys/types.h>
#include <sys/sysctl.h>

#import "parser.h"

#pragma mark - #define

// Variavel usada para mostrar a resposta do servidor em DEBUG
#define	PRINT_XMLPARSE	0

#pragma mark - LibXML parser declarations

// Function prototypes for SAX callbacks. This sample implements a minimal subset of SAX callbacks.
// Depending on your application's needs, you might want to implement more callbacks.
static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX(void * ctx, const xmlChar * ch, int len);
static void errorEncounteredSAX(void * ctx, const char * msg, ...);

// The handler struct has positions for a large number of callback functions. If NULL is supplied at a given position,
// that callback functionality won't be used. Refer to libxml documentation at http://www.xmlsoft.org for more information
// about the SAX callbacks.
static xmlSAXHandler simpleSAXHandlerStruct = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,						/* attributeDecl */
    NULL,                       /* elementDecl */
    NULL,                       /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    NULL,                       /* startDocument */
    NULL,                       /* endDocument */
    NULL,                       /* startElement*/
    NULL,                       /* endElement */
    NULL,                       /* reference */
    charactersFoundSAX,         /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncounteredSAX,        /* error */
    NULL,                       /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    NULL,                       /* cdataBlock */
    NULL,                       /* externalSubset */
    XML_SAX2_MAGIC,             //
    NULL,
    startElementSAX,            /* startElementNs */
    endElementSAX,              /* endElementNs */
    NULL,                       /* serror */
};

static id sharedInstance;

#pragma mark - Parser implementation

@implementation parser

#pragma mark - @synthesize

@synthesize delegate, abortParse;
@synthesize asyncConnection, request, net;
@synthesize responseFromServer, characterBuffer, respostaXML, extraData;
@synthesize whatToDo, storingCharacters, parsingXMLItem;
@synthesize parsedContent;
@synthesize mensagem;

#pragma mark - Singleton Methods

// Variavel para permitir compatilhar a função de parse entre diversas páginas, sem a necessidade de criar variaveis adicionais
+ (id)shared {
	if (sharedInstance == nil) {
		sharedInstance = [[parser alloc] init];
	}
	return sharedInstance;
}

- (void)destroy {
	[self release];
}

#pragma mark - Memory Management

- (void)dealloc {
	whatToDo = DONOTHING;

	delegate = nil;

	self.parsedContent = nil;

	self.responseFromServer = nil;
	self.characterBuffer = nil;
	self.respostaXML = nil;
	self.mensagem = nil;
	self.extraData = nil;

	self.net = nil;
	self.request = nil;
	self.asyncConnection = nil;
	sharedInstance = nil;

	[super dealloc];
}

#pragma mark - Network Delegate Methods

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[self.responseFromServer setLength:0];

#if PRINT_XMLPARSE
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		NSInteger status = [(NSHTTPURLResponse *)response statusCode];
		NSDictionary *dict = [(NSHTTPURLResponse *)response allHeaderFields];
		NSString *rsp = [NSHTTPURLResponse localizedStringForStatusCode:status];
		NSLog(@"status = %d", status);
		NSLog(@"header = %@", dict);
		NSLog(@"%@", rsp);
		NSLog(@"%@", response.MIMEType);
	}
#endif

	fileNotFound = NO;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (!fileNotFound) {
		if (self.responseFromServer == nil)
			self.responseFromServer = [[[NSMutableData alloc] initWithCapacity:2048] autorelease];
		
		[self.responseFromServer appendData:data];
	}
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	isParsing = NO;
	self.asyncConnection = nil;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	if (delegate && [delegate respondsToSelector:@selector(showNetworkErrorMessage)]) {
		[delegate showNetworkErrorMessage];
	}
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
#if PRINT_XMLPARSE
	NSString *theXML = [[NSString alloc] initWithBytes:[self.responseFromServer mutableBytes] length:[self.responseFromServer length] encoding:NSISOLatin1StringEncoding];
	NSLog(@"%@", theXML);
	[theXML release];
#endif

	[self.asyncConnection cancel];
	self.asyncConnection = nil;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	if (whatToDo == DOSYNCDONE) {
		if (delegate && [delegate respondsToSelector:@selector(returnFromParse:withData:)]) {
			[delegate returnFromParse:self withData:[NSKeyedArchiver archivedDataWithRootObject:@""]];
		}
	} else {
		if (self.responseFromServer != nil && !abortParse) {
			[self parseData:self.responseFromServer];
		}
	}
}

#pragma mark - networkMethods

- (void)checkNetwork {
	// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method "reachabilityChanged" will be called.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

	self.net = [[[networkMethods alloc] init] autorelease];
	[self.net setDelegate:self];
	[self.net checkHostAvailability:MYDOMAIN];
}

// Called by Reachability whenever status changes.
- (void)reachabilityChanged:(NSNotification *)notification {
	Reachability *curReach = [notification object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
	[self.net updateInterfaceWithReachability:curReach];
}

- (void)networkStatusChanged:(BOOL)networkIsAvailable {
	if (!networkIsAvailable) {
		if (delegate && [delegate respondsToSelector:@selector(showNoNetworkErrorMessage)]) {
			[delegate showNoNetworkErrorMessage];
		}

	} else {
		if (self.request) {
			self.asyncConnection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self] autorelease];
			if (self.asyncConnection) {
				self.responseFromServer = nil;
				[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
				
			} else {
				if (delegate && [delegate respondsToSelector:@selector(showNetworkErrorMessage)]) {
					[delegate showNetworkErrorMessage];
				}
			}
		} else {
			if (delegate && [delegate respondsToSelector:@selector(processNetworkActivity)]) {
				[delegate processNetworkActivity];
			}
		}
	}

	[self.net stopNetworkNotifer];
	[self.net setDelegate:nil];
	self.net = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

#pragma mark - Parser Methods

// Função para abortar o parse caso a página em questão não esteja mais em foco
- (void)abortLibXMLParse {
	if (isParsing) {
		abortParse = YES;

		// Parar o Spin de rede
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

		// Parar atividade de rede
		[self.net stopNetworkNotifer];
		[self.net setDelegate:nil];
		self.net = nil;
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
	}
}

// Função para preparar o parse bloqueando a execução do aplicativo até sua finalização, evitando conflitos
- (void)parse:(int)whatToParse withParam:(id)param {
	NSString *url = nil;
	NSString *body = nil;

	whatToDo = whatToParse;
	isParsing = YES;
	abortParse = NO;

	// Apaga mensagens de erro anteriores
	self.mensagem = nil;
	self.respostaXML = nil; self.respostaXML = [NSMutableArray array];

	switch (whatToDo) {
		case GETUSERPASSWORD:
		case DOUSERLOGIN: {
			if (param != nil) {
				if ([param isKindOfClass:[NSDictionary class]]) {
					url = [NSString stringWithFormat:@"%@%@%@", APIPROTOCOL, MYURL, [param objectForKey:@"url"]];
					body = [param objectForKey:@"body"];
				}
			}
		} break;

		case OBTERTRANSACTIONS:
		case OBTERUSERACCOUNTS:
		case OBTERUSERCATEGORIES:
		case OBTERUSERSETTINGS: {
			if (param != nil) {
				if ([param isKindOfClass:[NSDictionary class]]) {
					url = [NSString stringWithFormat:@"%@%@%@", APIPROTOCOL, MYURL, [param objectForKey:@"url"]];
					url = [url stringByAppendingString:[param objectForKey:@"key"]];
				}
			}
		} break;

		case DOSYNC: {
			if (param != nil) {
				if ([param isKindOfClass:[NSDictionary class]]) {
					url = [NSString stringWithFormat:@"%@%@%@", APIPROTOCOL, MYURL, [param objectForKey:@"url"]];
					url = [url stringByAppendingString:[param objectForKey:@"key"]];
					body = [param objectForKey:@"body"];
				}
			}
		} break;

		case DOSYNCDONE: {
			if (param != nil) {
				if ([param isKindOfClass:[NSDictionary class]]) {
					url = [NSString stringWithFormat:@"%@%@%@", APIPROTOCOL, MYURL, [param objectForKey:@"url"]];
					url = [url stringByAppendingString:[param objectForKey:@"key"]];
				}
			}
		} break;

		default:
			break;
	}

	if (url != nil) {
		self.request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
		if (self.request) {
			if (body != nil) {
				[self.request addValue:@"text/xml;" forHTTPHeaderField:@"Content-Type"];
				[self.request setHTTPMethod:@"POST"];
				[self.request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
			}
			if (whatToDo == DOSYNCDONE) {
				[self.request setHTTPMethod:@"DELETE"];
			}
			
			[self checkNetwork];

		} else {
			if (delegate && [delegate respondsToSelector:@selector(showNetworkErrorMessage)]) {
				[delegate showNetworkErrorMessage];
			}
		}
	}

	body = nil; url = nil;
}

// Função para executar o parse
- (void)parseData:(NSMutableData *)data {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    self.characterBuffer = [NSMutableData data];

	if (isParsing) {
		erroXML = NO;
		if ([data length] > 0) {
			// Iniciar o Parse
			context = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, self, NULL, 0, NULL);
			xmlParseChunk(context, (const char *)[data bytes], [data length], 0);
			xmlFreeParserCtxt(context);

			// Parse Concluido, tratar cada resposta
			[self didFindAnswer];
		} else {
			erroXML = YES;
			if (delegate && [delegate respondsToSelector:@selector(showErrorMessage)]) {
				[delegate showErrorMessage];
			}
		}
	}

	[pool release];
}

#pragma mark - Parser Specifics Methods

// Character data is appended to a buffer until the current element ends.
- (void)appendCharacters:(const char *)charactersFound length:(NSInteger)length {
	[self.characterBuffer appendBytes:charactersFound length:length];
}

// Create a string with the character data using UTF-8 encoding. UTF-8 is the default XML data encoding.
- (NSString *)currentString {
	NSString *currentString = [[[NSString alloc] initWithData:self.characterBuffer encoding:NSUTF8StringEncoding] autorelease];
	[self.characterBuffer setLength:0];
	return currentString;
}

// Função para "finalizar" a TAG
- (void)finishedCurrentTAG {
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];

	if (abortParse)	
		xmlParseChunk(context, NULL, 0, 1);

	switch (whatToDo) {
		case GETUSERPASSWORD:
		case DOUSERLOGIN:
		case OBTERTRANSACTIONS:
		case OBTERUSERACCOUNTS:
		case OBTERUSERCATEGORIES:
		case OBTERUSERSETTINGS:
		case DOSYNC: {
			[self.respostaXML addObject:self.parsedContent];
		} break;

		default:
			break;
	}
}

// Função para formatar corretamente valores
- (NSString *)prepareXMLValue:(NSString *)valor {
	NSString *returnValue = @"";

	if (![valor isEqualToString:@""] && valor != nil) {
		NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
		[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[formatter setGroupingSeparator:@"."];
		[formatter setDecimalSeparator:@","];
		NSNumber *newValue = [formatter numberFromString:valor];

		if (newValue == nil) {
			[formatter setGroupingSeparator:@","];
			[formatter setDecimalSeparator:@"."];
			newValue = [formatter numberFromString:valor];
		}

		[formatter setGroupingSeparator:@""];
		[formatter setDecimalSeparator:@"."];
		returnValue = [formatter stringFromNumber:newValue];
		formatter = nil;
	}

	return returnValue;
}

// Função para formatar a data no padrão próprio do aplicativo
- (NSDate *)prepareXMLDate:(NSString *)valor {
	NSString *t1 = valor;
	t1 = [t1 stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	t1 = [t1 stringByReplacingOccurrencesOfString:@"\t" withString:@""];
	t1 = [t1 stringByReplacingOccurrencesOfString:@"	" withString:@""];
	
	NSDateFormatter	*dateFormatterfromFeed = [[NSDateFormatter alloc] init];
	[dateFormatterfromFeed setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"US"] autorelease]];
	[dateFormatterfromFeed setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];

	NSDate *t2 = [dateFormatterfromFeed dateFromString:t1];
	if (t2 == nil) {
		[dateFormatterfromFeed setDateFormat:@"EEE, dd MMM yyyy HH:mm zzz"];
		t2 = [dateFormatterfromFeed dateFromString:t1];
		if (t2 == nil) {
			[dateFormatterfromFeed setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
			t2 = [dateFormatterfromFeed dateFromString:t1];
			if (t2 == nil) {
				[dateFormatterfromFeed setDateFormat:@"dd/MM/yyyy"];
				t2 = [dateFormatterfromFeed dateFromString:t1];
				if (t2 == nil) {
					[dateFormatterfromFeed setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"pt_BR"] autorelease]];
					[dateFormatterfromFeed setDateFormat:@"dd/M/yyyy HH:mm:ss"];
				}
			}
		}
	}

	[dateFormatterfromFeed release]; dateFormatterfromFeed = nil;
	t1 = nil;

	return (t2 == nil ? [NSDate date] : t2);
}

#pragma mark - End Parser Methods

// Função para finalizar o parse (ao finalizar o arquivo)
// Returns a NSData object with the parsed data (respostaXML), if exist. Otherwise, return mensagem
// The Delegate must threat the content
- (void)didFindAnswer {
	if (!abortParse) {
		if (!erroXML) {
			if (delegate && [delegate respondsToSelector:@selector(returnFromParse:withData:)]) {
				if (self.mensagem == nil) {
					[delegate returnFromParse:self withData:[NSKeyedArchiver archivedDataWithRootObject:self.respostaXML]];
				} else {
					[delegate returnFromParse:self withData:[NSKeyedArchiver archivedDataWithRootObject:self.mensagem]];
				}
			}
			
		} else {
			if (delegate && [delegate respondsToSelector:@selector(showErrorMessage)]) {
				[delegate showErrorMessage];
			}
		}
	}
}

@end

#pragma mark - SAX Parsing Callbacks

// The following constants are the XML element names and their string lengths for parsing comparison.
// The lengths include the null terminator, to ensure exact matches.

// Login
static const char *kName_LOGINKEY = "api-key";
static const char *kName_LOGINMSG = "message";

// Settings
static const char *kName_SETTINGS = "config";
static const char *kName_SETTINGSOUTCOMES = "transactions-consider-only-done-outcomes";
static const char *kName_SETTINGSINCOMES = "transactions-consider-only-done-incomes";
static const char *kName_SETTINGSINCOMES2 = "transactions-consider-only-done_incomes";
static const char *kName_SETTINGSTRANSFERRESULT = "transactions-transfer-result";
static const char *kName_SETTINGSTRANSFERMONTH2 = "transactions-transfer-result-start-month";
static const char *kName_SETTINGSTRANSFERMONTH = "transactions-transfer-result-start_month";
static const char *kName_SETTINGSVERSION = "versao-mais";
static const char *kName_SETTINGSDONE = "transactions-set-done";

// Comum
static const char *kName_CREATEDAT = "created-at";
static const char *kName_DELETEDAT = "deleted-at";
static const char *kName_UPDATEDAT = "updated-at";
static const char *kName_ID = "id";
static const char *kName_NAME = "name";
static const char *kName_NONE = "none";
static const char *kName_USERID = "user-id";

// Categories - TAGS
static const char *kName_TAG = "tag";
static const char *kName_TAGCOLOR = "color";
static const char *kName_TAGMONTLY = "montly-ammount";
static const char *kName_TAGPARENTID = "parent-id";
static const char *kName_TAGPERMANENT = "permanent";
static const char *kName_TAGTRANSLATE = "translate";
static const char *kName_TAGCHILD = "child";

// Accounts
static const char *kName_ACCOUNT = "account";
static const char *kName_ACCOUNTFLAG = "flag";
static const char *kName_ACCOUNTFLAGICON = "flag-icon";
static const char *kName_ACCOUNTICON = "icon";
static const char *kName_ACCOUNTKIND = "kind";

// Transactions
static const char *kName_TRANSACTION = "transaction";
static const char *kName_TRANSACTIONACCOUNTID = "account-id";
static const char *kName_TRANSACTIONAMMOUNT = "ammount";
static const char *kName_TRANSACTIONDATE = "date";
static const char *kName_TRANSACTIONDESCRIPTION = "description";
static const char *kName_TRANSACTIONDONE = "done";
static const char *kName_TRANSACTIONINCOME = "income";
static const char *kName_TRANSACTIONOBSERVATION = "observation";
static const char *kName_TRANSACTIONREPEATFINDER = "repeat-finder";
static const char *kName_TRANSACTIONREPEATINDEX = "repeat-index";
static const char *kName_TRANSACTIONREPEATTOTAL = "repeat-total";
static const char *kName_TRANSACTIONREPEATTYPE = "repeat-type";
static const char *kName_TRANSACTIONSTARTRESULT = "start-result";
static const char *kName_TRANSACTIONTAGID = "tag-id";
static const char *kName_TRANSACTIONTRANSFER = "transfer";
static const char *kName_TRANSACTIONTRANSFERFROM = "transfer-from";
static const char *kName_TRANSACTIONTRANSFERID = "transfer-id";
static const char *kName_TRANSACTIONTRANSFERTO = "transfer-to";
static const char *kName_TRANSACTIONMOBILEID = "mobile-record-id";
static const char *kName_TRANSACTIONSYNCSTATUS = "sync-status";
static const char *kName_TRANSACTIONSYNCUUID = "uuid";
static const char *kName_TRANSACTIONSYNCREPEATID = "recurrence-uuid";

// SYNC
static const char *kName_SYNCEND = "end-time";

/*
 This callback is invoked when the parser finds the beginning of a node in the XML. For this application,
 out parsing needs are relatively modest - we need only match the node name. An "item" node is a record of
 data about a song. In that case we create a new Song object. The other nodes of interest are several of the
 child nodes of the Song currently being parsed. For those nodes we want to accumulate the character data
 in a buffer. Some of the child nodes use a namespace prefix. 
 */
static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, 
                            int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
    parser *parse = (parser *)ctx;

	switch (parse.whatToDo) {
		case GETUSERPASSWORD: {
			if (!strcmp((const char *)localname, kName_LOGINMSG)) {
				parse.mensagem = [NSString stringWithString:@""];
				parse.parsingXMLItem = YES;
				parse.storingCharacters = YES;
			}
		} break;

		case DOUSERLOGIN: {
			if (!strcmp((const char *)localname, kName_LOGINKEY)) {
				parse.parsedContent = [NSMutableDictionary dictionary];
				parse.parsingXMLItem = YES;
				parse.storingCharacters = YES;
				
			} else if (!strcmp((const char *)localname, kName_LOGINMSG)) {
				parse.mensagem = [NSString stringWithString:@""];
				parse.parsingXMLItem = YES;
				parse.storingCharacters = YES;
			}
		} break;

		case OBTERUSERSETTINGS: {
			if (!strcmp((const char *)localname, kName_SETTINGS)) {
				parse.parsedContent = [NSMutableDictionary dictionary];
				parse.parsingXMLItem = YES;

			} else if (parse.parsingXMLItem && 
				   ((!strcmp((const char *)localname, kName_SETTINGSOUTCOMES) || 
					 !strcmp((const char *)localname, kName_SETTINGSINCOMES) || 
					 !strcmp((const char *)localname, kName_SETTINGSINCOMES2) || 
					 !strcmp((const char *)localname, kName_SETTINGSTRANSFERRESULT) || 
					 !strcmp((const char *)localname, kName_SETTINGSTRANSFERMONTH) || 
					 !strcmp((const char *)localname, kName_SETTINGSTRANSFERMONTH2) || 
					 !strcmp((const char *)localname, kName_SETTINGSDONE) || 
					 !strcmp((const char *)localname, kName_SETTINGSVERSION)
					 ))) {
				parse.storingCharacters = YES;
			}
		} break;

		case OBTERUSERCATEGORIES: {
			if (!strcmp((const char *)localname, kName_TAG)) {
				parse.parsedContent = [NSMutableDictionary dictionary];
				parse.parsingXMLItem = YES;

			} else if (!strcmp((const char *)localname, kName_TAGCHILD)) {
				parse.parsingXMLItem = NO;

			} else if (parse.parsingXMLItem && 
					   ((!strcmp((const char *)localname, kName_TAGCOLOR) || 
						 !strcmp((const char *)localname, kName_CREATEDAT) || 
						 !strcmp((const char *)localname, kName_ID) || 
						 !strcmp((const char *)localname, kName_TAGMONTLY) || 
						 !strcmp((const char *)localname, kName_NAME) || 
						 !strcmp((const char *)localname, kName_NONE) || 
						 !strcmp((const char *)localname, kName_TAGPARENTID) || 
						 !strcmp((const char *)localname, kName_TAGPERMANENT) || 
						 !strcmp((const char *)localname, kName_TAGTRANSLATE) || 
						 !strcmp((const char *)localname, kName_UPDATEDAT) || 
						 !strcmp((const char *)localname, kName_USERID) || 
						 !strcmp((const char *)localname, kName_DELETEDAT)
						 ))) {
				parse.storingCharacters = YES;
			}
		} break;

		case OBTERUSERACCOUNTS: {
			if (!strcmp((const char *)localname, kName_ACCOUNT)) {
				parse.parsedContent = [NSMutableDictionary dictionary];
				parse.parsingXMLItem = YES;

			} else if (parse.parsingXMLItem && 
					   ((!strcmp((const char *)localname, kName_ACCOUNTFLAG) || 
						 !strcmp((const char *)localname, kName_CREATEDAT) || 
						 !strcmp((const char *)localname, kName_ID) || 
						 !strcmp((const char *)localname, kName_ACCOUNTFLAGICON) || 
						 !strcmp((const char *)localname, kName_NAME) || 
						 !strcmp((const char *)localname, kName_NONE) || 
						 !strcmp((const char *)localname, kName_ACCOUNTICON) || 
						 !strcmp((const char *)localname, kName_ACCOUNTKIND) || 
						 !strcmp((const char *)localname, kName_UPDATEDAT) || 
						 !strcmp((const char *)localname, kName_USERID) || 
						 !strcmp((const char *)localname, kName_DELETEDAT)
						 ))) {
				parse.storingCharacters = YES;
			}
		} break;

		case OBTERTRANSACTIONS:
		case DOSYNC: {
			if (!strcmp((const char *)localname, kName_TRANSACTION)) {
				parse.parsedContent = [NSMutableDictionary dictionary];
				[parse.parsedContent setObject:@"Transactions" forKey:@"entity"];
				parse.parsingXMLItem = YES;

			} else if (!strcmp((const char *)localname, kName_TAG)) {
				parse.parsedContent = [NSMutableDictionary dictionary];
				[parse.parsedContent setObject:@"Tags" forKey:@"entity"];
				parse.parsingXMLItem = YES;

			} else if (!strcmp((const char *)localname, kName_TAGCHILD)) {
				parse.parsingXMLItem = NO;

			} else if (!strcmp((const char *)localname, kName_ACCOUNT)) {
				parse.parsedContent = [NSMutableDictionary dictionary];
				[parse.parsedContent setObject:@"Accounts" forKey:@"entity"];
				parse.parsingXMLItem = YES;

			} else if (!strcmp((const char *)localname, kName_SETTINGS)) {
				parse.parsedContent = [NSMutableDictionary dictionary];
				[parse.parsedContent setObject:@"User_Config" forKey:@"entity"];
				parse.parsingXMLItem = YES;
				
			} else if (parse.parsingXMLItem && 
					   ((!strcmp((const char *)localname, kName_TRANSACTIONACCOUNTID) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONAMMOUNT) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONDATE) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONDESCRIPTION) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONDONE) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONINCOME) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONOBSERVATION) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONREPEATFINDER) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONREPEATINDEX) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONREPEATTOTAL) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONREPEATTYPE) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONSTARTRESULT) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONTAGID) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONTRANSFER) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONTRANSFERFROM) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONTRANSFERID) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONTRANSFERTO) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONMOBILEID) || 
						 !strcmp((const char *)localname, kName_TRANSACTIONSYNCSTATUS) ||
						 !strcmp((const char *)localname, kName_ID) || 
						 !strcmp((const char *)localname, kName_USERID) || 
						 !strcmp((const char *)localname, kName_CREATEDAT) || 
						 !strcmp((const char *)localname, kName_UPDATEDAT) || 
						 !strcmp((const char *)localname, kName_DELETEDAT) ||
						 !strcmp((const char *)localname, kName_SYNCEND) ||
						 !strcmp((const char *)localname, kName_ACCOUNTFLAG) || 
						 !strcmp((const char *)localname, kName_ACCOUNTFLAGICON) || 
						 !strcmp((const char *)localname, kName_NAME) || 
						 !strcmp((const char *)localname, kName_NONE) || 
						 !strcmp((const char *)localname, kName_ACCOUNTICON) || 
						 !strcmp((const char *)localname, kName_ACCOUNTKIND) ||
						 !strcmp((const char *)localname, kName_TAGCOLOR) || 
						 !strcmp((const char *)localname, kName_CREATEDAT) || 
						 !strcmp((const char *)localname, kName_TAGMONTLY) || 
						 !strcmp((const char *)localname, kName_TAGPARENTID) || 
						 !strcmp((const char *)localname, kName_TAGPERMANENT) || 
						 !strcmp((const char *)localname, kName_TAGTRANSLATE) ||
						 !strcmp((const char *)localname, kName_SETTINGSOUTCOMES) || 
						 !strcmp((const char *)localname, kName_SETTINGSINCOMES) || 
						 !strcmp((const char *)localname, kName_SETTINGSINCOMES2) || 
						 !strcmp((const char *)localname, kName_SETTINGSTRANSFERRESULT) || 
						 !strcmp((const char *)localname, kName_SETTINGSTRANSFERMONTH) || 
						 !strcmp((const char *)localname, kName_SETTINGSTRANSFERMONTH2) || 
						 !strcmp((const char *)localname, kName_SETTINGSDONE) || 
						 !strcmp((const char *)localname, kName_SETTINGSVERSION) ||
						 !strcmp((const char *)localname, kName_TRANSACTIONSYNCUUID) ||
						 !strcmp((const char *)localname, kName_TRANSACTIONSYNCREPEATID)
						 ))) {
				parse.storingCharacters = YES;
			}
		} break;

		default:
			break;
	}
}

/*
 This callback is invoked when the parse reaches the end of a node. At that point we finish processing that node,
 if it is of interest to us. For "item" nodes, that means we have completed parsing a Song object. We pass the song
 to a method in the superclass which will eventually deliver it to the delegate. For the other nodes we
 care about, this means we have all the character data. The next step is to create an NSString using the buffer
 contents and store that with the current Song object.
 */
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {    
	parser *parse = (parser *)ctx;

	if ((parse.whatToDo == OBTERUSERCATEGORIES || parse.whatToDo == DOSYNC) && !strcmp((const char *)localname, kName_TAG)) {
		parse.parsingXMLItem = YES;
	}

	if (parse.parsingXMLItem == NO) return;

	NSString *local = [[[NSString alloc] initWithCString:(const char *)localname encoding:NSUTF8StringEncoding] autorelease];
	NSString *key = [local stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
	if (!strcmp((const char *)localname, kName_TRANSACTIONDESCRIPTION)) {
		key = [key stringByAppendingString:@"_text"];
	}
	local = nil;

	switch (parse.whatToDo) {
		case GETUSERPASSWORD: {
			if (!strcmp((const char *)localname, kName_LOGINMSG)) {
				parse.mensagem = [parse currentString];
				parse.parsingXMLItem = NO;
			}
		} break;
			
		case DOUSERLOGIN: {
			if (!strcmp((const char *)localname, kName_LOGINKEY)) {
				[parse.parsedContent setObject:[parse currentString] forKey:key];
				[parse finishedCurrentTAG];
				parse.parsingXMLItem = NO;
			} else if (!strcmp((const char *)localname, kName_LOGINMSG)) {
				parse.mensagem = [parse currentString];
				parse.parsingXMLItem = NO;
			}
		} break;

		case OBTERUSERSETTINGS: {
			if (!strcmp((const char *)localname, kName_SETTINGS)) {
				[parse finishedCurrentTAG];
				parse.parsingXMLItem = NO;
			} else if (!strcmp((const char *)localname, kName_SETTINGSOUTCOMES) ||
					   !strcmp((const char *)localname, kName_SETTINGSINCOMES) ||
					   !strcmp((const char *)localname, kName_SETTINGSINCOMES2) ||
					   !strcmp((const char *)localname, kName_SETTINGSTRANSFERRESULT) ||
					   !strcmp((const char *)localname, kName_SETTINGSTRANSFERMONTH) ||
					   !strcmp((const char *)localname, kName_SETTINGSTRANSFERMONTH2) ||
					   !strcmp((const char *)localname, kName_SETTINGSDONE) || 
					   !strcmp((const char *)localname, kName_SETTINGSVERSION)
					   ) {
				[parse.parsedContent setObject:[parse currentString] forKey:key];
			}
		} break;

		case OBTERUSERCATEGORIES: {
			if (!strcmp((const char *)localname, kName_TAG)) {
				[parse finishedCurrentTAG];
				parse.parsingXMLItem = NO;
			} else if (!strcmp((const char *)localname, kName_TAGCHILD)) {
				parse.parsingXMLItem = YES;
			} else if (!strcmp((const char *)localname, kName_TAGCOLOR) ||
					   !strcmp((const char *)localname, kName_CREATEDAT) || 
					   !strcmp((const char *)localname, kName_ID) || 
					   !strcmp((const char *)localname, kName_TAGMONTLY) || 
					   !strcmp((const char *)localname, kName_NAME) || 
					   !strcmp((const char *)localname, kName_NONE) || 
					   !strcmp((const char *)localname, kName_TAGPARENTID) || 
					   !strcmp((const char *)localname, kName_TAGPERMANENT) || 
					   !strcmp((const char *)localname, kName_TAGTRANSLATE) || 
					   !strcmp((const char *)localname, kName_UPDATEDAT) || 
					   !strcmp((const char *)localname, kName_USERID) || 
					   !strcmp((const char *)localname, kName_DELETEDAT)
					   ) {
				[parse.parsedContent setObject:[parse currentString] forKey:key];
			}
		} break;

		case OBTERUSERACCOUNTS: {
			if (!strcmp((const char *)localname, kName_ACCOUNT)) {
				[parse finishedCurrentTAG];
				parse.parsingXMLItem = NO;
			} else if (!strcmp((const char *)localname, kName_ACCOUNTFLAG) || 
					   !strcmp((const char *)localname, kName_CREATEDAT) || 
					   !strcmp((const char *)localname, kName_ID) || 
					   !strcmp((const char *)localname, kName_ACCOUNTFLAGICON) || 
					   !strcmp((const char *)localname, kName_NAME) || 
					   !strcmp((const char *)localname, kName_NONE) || 
					   !strcmp((const char *)localname, kName_ACCOUNTICON) || 
					   !strcmp((const char *)localname, kName_ACCOUNTKIND) || 
					   !strcmp((const char *)localname, kName_UPDATEDAT) || 
					   !strcmp((const char *)localname, kName_USERID) || 
					   !strcmp((const char *)localname, kName_DELETEDAT)
					   ) {
				[parse.parsedContent setObject:[parse currentString] forKey:key];
			}
		} break;

		case OBTERTRANSACTIONS:
		case DOSYNC: {
			if (!strcmp((const char *)localname, kName_ACCOUNT) ||
				!strcmp((const char *)localname, kName_TRANSACTION) ||
				!strcmp((const char *)localname, kName_SETTINGS) ||
				!strcmp((const char *)localname, kName_TAG)
				) {
				[parse finishedCurrentTAG];
				parse.parsingXMLItem = NO;

			} else if (!strcmp((const char *)localname, kName_TAGCHILD)) {
				parse.parsingXMLItem = YES;

			} else if (!strcmp((const char *)localname, kName_TRANSACTIONACCOUNTID) || 
						!strcmp((const char *)localname, kName_TRANSACTIONAMMOUNT) || 
						!strcmp((const char *)localname, kName_TRANSACTIONDATE) || 
						!strcmp((const char *)localname, kName_TRANSACTIONDESCRIPTION) || 
						!strcmp((const char *)localname, kName_TRANSACTIONDONE) || 
						!strcmp((const char *)localname, kName_TRANSACTIONINCOME) || 
						!strcmp((const char *)localname, kName_TRANSACTIONOBSERVATION) || 
						!strcmp((const char *)localname, kName_TRANSACTIONREPEATFINDER) || 
						!strcmp((const char *)localname, kName_TRANSACTIONREPEATINDEX) || 
						!strcmp((const char *)localname, kName_TRANSACTIONREPEATTOTAL) || 
						!strcmp((const char *)localname, kName_TRANSACTIONREPEATTYPE) || 
						!strcmp((const char *)localname, kName_TRANSACTIONSTARTRESULT) || 
						!strcmp((const char *)localname, kName_TRANSACTIONTAGID) || 
						!strcmp((const char *)localname, kName_TRANSACTIONTRANSFER) || 
						!strcmp((const char *)localname, kName_TRANSACTIONTRANSFERFROM) || 
						!strcmp((const char *)localname, kName_TRANSACTIONTRANSFERID) || 
						!strcmp((const char *)localname, kName_TRANSACTIONTRANSFERTO) || 
						!strcmp((const char *)localname, kName_TRANSACTIONMOBILEID) || 
						!strcmp((const char *)localname, kName_TRANSACTIONSYNCSTATUS) ||
						!strcmp((const char *)localname, kName_ID) || 
						!strcmp((const char *)localname, kName_USERID) || 
						!strcmp((const char *)localname, kName_CREATEDAT) || 
						!strcmp((const char *)localname, kName_UPDATEDAT) || 
						!strcmp((const char *)localname, kName_DELETEDAT) ||
						!strcmp((const char *)localname, kName_SYNCEND) ||
						!strcmp((const char *)localname, kName_ACCOUNTFLAG) || 
						!strcmp((const char *)localname, kName_ACCOUNTFLAGICON) || 
						!strcmp((const char *)localname, kName_NAME) || 
						!strcmp((const char *)localname, kName_NONE) || 
						!strcmp((const char *)localname, kName_ACCOUNTICON) || 
						!strcmp((const char *)localname, kName_ACCOUNTKIND) ||
						!strcmp((const char *)localname, kName_TAGCOLOR) || 
						!strcmp((const char *)localname, kName_CREATEDAT) || 
						!strcmp((const char *)localname, kName_TAGMONTLY) || 
						!strcmp((const char *)localname, kName_TAGPARENTID) || 
						!strcmp((const char *)localname, kName_TAGPERMANENT) || 
						!strcmp((const char *)localname, kName_TAGTRANSLATE) ||
						!strcmp((const char *)localname, kName_SETTINGSOUTCOMES) || 
						!strcmp((const char *)localname, kName_SETTINGSINCOMES) || 
						!strcmp((const char *)localname, kName_SETTINGSINCOMES2) || 
						!strcmp((const char *)localname, kName_SETTINGSTRANSFERRESULT) || 
						!strcmp((const char *)localname, kName_SETTINGSTRANSFERMONTH) || 
						!strcmp((const char *)localname, kName_SETTINGSTRANSFERMONTH2) || 
						!strcmp((const char *)localname, kName_SETTINGSDONE) || 
						!strcmp((const char *)localname, kName_SETTINGSVERSION) ||
					    !strcmp((const char *)localname, kName_TRANSACTIONSYNCUUID) ||
					    !strcmp((const char *)localname, kName_TRANSACTIONSYNCREPEATID)
						) {
				[parse.parsedContent setObject:[parse currentString] forKey:key];
			}
		} break;

		default:
			parse.parsingXMLItem = NO;
			break;
	}

	key = nil;
	parse.storingCharacters = NO;
}

// This callback is invoked when the parser encounters character data inside a node. The parser class determines how to use the character data.
static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
	parser *parse = (parser *)ctx;
	// A state variable, "storingCharacters", is set when nodes of interest begin and end. 
	// This determines whether character data is handled or ignored.
	if (parse.storingCharacters == NO) return;
	[parse appendCharacters:(const char *)ch length:len];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
static void errorEncounteredSAX(void *ctx, const char *msg, ...) {
	// Handle errors as appropriate for your application.
	//NSCAssert(NO, @"Unhandled error encountered during SAX parse.");
}
