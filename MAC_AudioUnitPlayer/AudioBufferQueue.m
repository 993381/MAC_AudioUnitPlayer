//
//  AudioBufferQueue.m
//  PCMPlayer
//
//  Created by Ruiwen Feng on 2017/5/31.
//  Copyright © 2017年 Ruiwen Feng. All rights reserved.
//

#import "AudioBufferQueue.h"

#if TARGET_OS_IOS
#define BUFFER_SIZE (186*2)
#elif TARGET_OS_OSX
#define BUFFER_SIZE 186
#endif


typedef struct AudioBufferQueueUnit {
    
    AudioBuffer                 * _audioBuffer;
    struct AudioBufferQueueUnit * _nextUnit;
    
    
}QueueUnit;

@interface AudioBufferQueue (){
    QueueUnit  * header;
    QueueUnit  * rear;
    unsigned int current_num;
}

@end

@implementation AudioBufferQueue

- (instancetype)init
{
    self = [super init];
    if (self) {
        current_num = 0;
        header = NULL;
        rear = NULL;
    }
    return self;
}

//存入一个音频buffer
- (BOOL)insertBuffer:(AudioBuffer*)buffer {
    
    if (current_num < AUDIO_BUFFER_QUEUE_MAX_SIZE-2) {   //数据没有满。
        
        //可以拆分为多个buff之所以要拆分，是因为audioUnit的播放通过回调接收音频
        if (buffer->mDataByteSize > BUFFER_SIZE) {
            
            [self seprateBuffer:buffer];
            
            return YES;
        }
        
        //不需要拆分，则直接copy
        current_num += 1;
        QueueUnit *unit = NULL;
        unit = malloc(sizeof(QueueUnit*));
        unit->_audioBuffer = malloc(sizeof(AudioBuffer*));
        [self copySourceBuffer:buffer toDestinationBuffer:unit->_audioBuffer];
        if (current_num == 1) { //如果是第一个数据。
            header = unit;
            rear = unit;
        }
        else {   //不是第一个数据。
            rear->_nextUnit = unit;
            rear = unit;
        }
    }
    else {     //数据满了。
        printf("audio Queue if full");
        return NO;
    }
    return YES;
}


- (BOOL)seprateBuffer:(AudioBuffer*)buffer {
    
    //需要拆分的数量
    int n = buffer->mDataByteSize%BUFFER_SIZE?buffer->mDataByteSize/BUFFER_SIZE+1:buffer->mDataByteSize/BUFFER_SIZE;
    
    for (unsigned int i = 0; i < n; i ++) {
        current_num += 1;
        QueueUnit *unit = NULL;
        unit = malloc(sizeof(QueueUnit*));
        unit->_audioBuffer = malloc(sizeof(AudioBuffer*));
        UInt32 size = BUFFER_SIZE;
        if (i == n-1) {
            //最后一个的大小可能需要计算
            size = buffer->mDataByteSize - (n-1)*BUFFER_SIZE;
        }
        NSLog(@"%d %d %d %d",size,buffer->mDataByteSize,n,(n-1)*BUFFER_SIZE);
        [self createBuffer:unit->_audioBuffer data:buffer->mData+i*BUFFER_SIZE size:size];
        if (current_num == 1) { //如果是第一个数据。
            header = unit;
            rear = unit;
        }
        else {   //不是第一个数据。
            rear->_nextUnit = unit;
            rear = unit;
        }
    }
    
    
    return YES;
}



//取出一个音频buffer
- (BOOL)extractBuffer:(void(^)(AudioBuffer*))callback {
    
    //没有内容。
    if (current_num <= DELAY_SEC*45 ) {
        return NO;
    }
    
    dispatch_block_t block = ^{
        callback(header->_audioBuffer); //回调出去。
        current_num --;
        QueueUnit * unit = header;     //头部向后移动
        header = header->_nextUnit;
        [self destoryQueueUnit:unit];//用完删除
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block);
    
    return YES;
}



- (void)copySourceBuffer:(AudioBuffer*)srcbuffer toDestinationBuffer:(AudioBuffer*)dstbuffer {
    [self createBuffer:dstbuffer data:srcbuffer->mData size:srcbuffer->mDataByteSize];
//    
//    char * buffer = malloc(srcbuffer->mDataByteSize);
//    memcpy(buffer, srcbuffer->mData, srcbuffer->mDataByteSize);
//    dstbuffer->mDataByteSize = srcbuffer->mDataByteSize;
//    dstbuffer->mData = buffer;
}

- (void)createBuffer:(AudioBuffer*)srcbuffer data:(void*)data size:(UInt32)size {
    char * buffer = malloc(size);
    memcpy(buffer, data, size);
    srcbuffer->mDataByteSize = size;
    srcbuffer->mData = buffer;
}

- (void)destoryQueueUnit:(QueueUnit*)unit {
    free(unit->_audioBuffer->mData);
    unit->_audioBuffer = NULL;
    unit->_nextUnit = NULL;
    free(unit);
}

- (void)reSet {
    
    QueueUnit * unit = header;
    //从头删除。
    do {
        QueueUnit * TempUnit = unit;
        unit = TempUnit->_nextUnit;
        [self destoryQueueUnit:TempUnit];
    } while (unit != NULL);
    header = NULL;
    rear = NULL;
    current_num = 0;

}

- (void)dealloc
{
    [self reSet];
}

@end
