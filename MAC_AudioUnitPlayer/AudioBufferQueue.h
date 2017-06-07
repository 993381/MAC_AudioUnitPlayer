//
//  AudioBufferQueue.h
//  PCMPlayer
//
//  Created by Ruiwen Feng on 2017/5/31.
//  Copyright © 2017年 Ruiwen Feng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define AUDIO_BUFFER_QUEUE_MAX_SIZE 50000

//延迟时间
#define DELAY_SEC 0

@interface AudioBufferQueue : NSObject

- (BOOL)insertBuffer:(AudioBuffer*)buffer;
- (BOOL)extractBuffer:(void(^)(AudioBuffer*))callback;

@end
