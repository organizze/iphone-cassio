//
//  Customization.h
//
//  Created by Cassio Rossi on 05/08/11.
//  Copyright 2011 Kazzio Software. All rights reserved.
//

// Parametros de Customização
// Usar OU cor OU imagem
// Para o parametro não desejado, colocar @"", senão a COR em Hexadecimal OU o nome do arquivo da IMAGEM (tamanhos 320x44 e 640x88)

// Barra de Navegação - Parte superior do App
#define	CUSTOMNAVBAR			[NSDictionary dictionaryWithObjectsAndKeys:@"0x007575" , @"COR", @"navigationbar.png", @"IMAGEM", nil]

// Cores do App
#define HEADERCOLOR				UIColorFromRGB(0xDCEFEF)
#define LINESEPARATORCOLOR		UIColorFromRGB(0xDEE6E6)
#define TABLESEPARATORCOLOR		UIColorFromRGB(0xD4D4D4)
//Cor da movimentações #111111
#define GREENCOLOR				UIColorFromRGB(0x36AA59)
#define REDCOLOR				UIColorFromRGB(0xEF4040)
#define GRAYOVERWHITECOLOR		UIColorFromRGB(0x9DB0B0)
#define GRAYCOLOR				UIColorFromRGB(0x949FA6)
#define GREENTEXTCOLOR			UIColorFromRGB(0x006666)
#define GRAYTEXTCOLOR			UIColorFromRGB(0x333333)
#define YELLOWCOLOR				UIColorFromRGB(0xFFFFDD)

// Parâmetros para obtenção dos dados
#define	PRODUCAO				1

#define	MYPROTOCOL				@"http://"
#define	APIPROTOCOL				@"https://"

#if PRODUCAO
	#define	MYSERVER			@"pessoal."
	#define	MYDOMAIN_ONLY		@"organizze.com.br"
#else
	#define	MYSERVER			@""
	#define	MYDOMAIN_ONLY		@"organizze-staging.herokuapp.com"
#endif

#define	MYPATH					@"/"
#define	MYDOMAIN				[NSString stringWithFormat:@"%@%@", MYSERVER, MYDOMAIN_ONLY]
#define	MYURL					[NSString stringWithFormat:@"%@%@%@", MYSERVER, MYDOMAIN_ONLY, MYPATH]

#define EXTRA					@"secret_key=f6b61fe7fca299b34050558f3dfec75a4efa9aaa"

#define USERLOGIN				[NSString stringWithFormat:@"api/authentication.xml?%@", EXTRA]
#define USERSETTINGS			[NSString stringWithFormat:@"settings.xml?%@&api_key=", EXTRA]
#define USERCATEGORY			[NSString stringWithFormat:@"tags.xml?%@&api_key=", EXTRA]
#define USERACCOUNTS			[NSString stringWithFormat:@"accounts.xml?%@&api_key=", EXTRA]
#define TRANSACTIONS			[NSString stringWithFormat:@"transactions.xml?%@&api_key=", EXTRA]
#define USERPASSWORD			[NSString stringWithFormat:@"api/password-recovery.xml?%@", EXTRA]
#define SYNC					[NSString stringWithFormat:@"api/synchronization.xml?%@&api_key=", EXTRA]
#define SYNCDONE				[NSString stringWithFormat:@"api/synchronization/%@.xml?%@&api_key=", [[sharedMethods shared] getMyUDID], EXTRA]

#define USERREGISTRY			[NSString stringWithFormat:@"%@%@%@", APIPROTOCOL, MYURL, @"cadastre-se-mobile?iphone_app=1"]
#define ORGANIZZEMAIS			[NSString stringWithFormat:@"%@%@%@", APIPROTOCOL, MYURL, @"organizzemais?iphone_app=1"]

