//
//  SoapHandlerBlocks.h
//
//  Created by Sebastien Martin on 11-04-11.
//

#import <Foundation/Foundation.h>
#import "SoapHandler.h"

@class SoapFault;

typedef void (^OnLoadBlock_t)(id);
typedef void (^OnErrorBlock_t)(NSError *);
typedef void (^OnFaultBlock_t)(SoapFault *);

// This class is a wrapper around the Sudz-C SoapHandler class.  It allows the caller
// to specify callbacks using blocks instead of selectors.
@interface SoapHandlerBlocks : SoapHandler

@property (nonatomic, copy, readonly) OnLoadBlock_t(onLoadBlock);
@property (nonatomic, copy, readonly) OnErrorBlock_t(onErrorBlock);
@property (nonatomic, copy, readonly) OnFaultBlock_t(onFaultBlock);

@property (nonatomic, assign) BOOL canCallbackOnBackgroundThread;
@property (nonatomic, assign) NSOperationQueuePriority queuePriority;

- (id)initWithOnLoad:(OnLoadBlock_t)onLoad onError:(OnErrorBlock_t)onError onFault:(OnFaultBlock_t)onFault;
+ (SoapHandlerBlocks *)noOpHandler;

- (void)onload:(id)value;
- (void)onerror:(NSError *)error;
- (void)onfault:(SoapFault *)fault;

@end
