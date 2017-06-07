//
//  G711.h
//  G711
//
//  Created by Ruiwen Feng on 2017/6/1.
//  Copyright © 2017年 Ruiwen Feng. All rights reserved.
//

#ifndef G711_h
#define G711_h

#include <stdio.h>

int g711a_encode( unsigned char g711_data[], const short amp[], int len );

int g711a_decode( short amp[], const unsigned char g711a_data[], int g711a_bytes );

#endif /* G711_h */
