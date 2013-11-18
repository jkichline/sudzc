//
//  SoapHandlerBlocks.m
//
//  Created by Sebastien Martin on 11-04-11.
//

#import "SoapHandlerBlocks.h"

@interface  SoapHandlerBlocks  ()

@property (nonatomic, copy) OnLoadBlock_t(onLoadBlock);
@property (nonatomic, copy) OnErrorBlock_t(onErrorBlock);
@property (nonatomic, copy) OnFaultBlock_t(onFaultBlock);

@end


@implementation SoapHandlerBlocks

- (id)initWithOnLoad:(OnLoadBlock_t)onLoad onError:(OnErrorBlock_t)onError onFault:(OnFaultBlock_t)onFault
{
    self = [super init];
    if (self) {
        _canCallbackOnBackgroundThread = NO; // Default, special cases like Adapters will set this to YES.
        _queuePriority = NSOperationQueuePriorityNormal;

        _onLoadBlock = [onLoad copy];
        _onErrorBlock = [onError copy];
        _onFaultBlock = [onFault copy];
  }
  return self;
}

+ (SoapHandlerBlocks *)noOpHandler
{
    OnLoadBlock_t onLoad = ^(id value) {};
    OnErrorBlock_t onError = ^(NSError *value) {};
    OnFaultBlock_t onFault = ^(SoapFault *value) {};

    SoapHandlerBlocks *noOpHandler = [[SoapHandlerBlocks alloc] initWithOnLoad:onLoad onError:onError onFault:onFault];
    noOpHandler.canCallbackOnBackgroundThread = YES;

    return noOpHandler;
}


#pragma mark - Overrides

- (void)onload:(id)value
{
    if (!self.canCallbackOnBackgroundThread && ![NSThread isMainThread]) {
        // Wait until done to avoid memory allocation problems. This is a background thread, so there shouldn't be an impact on the UI.
        [self performSelectorOnMainThread:@selector(onload:) withObject:value waitUntilDone:YES];
        return;
    }

  if (self.onLoadBlock) {
      self.onLoadBlock(value);
  }
  else {
      [super onload:value];
  }
}

- (void)onerror:(NSError *)error
{
    if (self.canCallbackOnBackgroundThread == NO && [NSThread isMainThread] == NO) {
        // Wait until done to avoid memory allocation problems.  This is a background thread, so there shouldn't be an impact on the UI.
        [self performSelectorOnMainThread:@selector(onerror:) withObject:error waitUntilDone:YES];
        return;
    }

  if (self.onErrorBlock) {
      self.onErrorBlock(error);
  }
  else {
      [super onerror:error];
  }
}

- (void)onfault:(SoapFault *)fault
{
    if (self.canCallbackOnBackgroundThread == NO && [NSThread isMainThread] == NO) {
        // Wait until done to avoid memory allocation problems.  This is a background thread, so there shouldn't be an impact on the UI.
        [self performSelectorOnMainThread:@selector(onfault:) withObject:fault waitUntilDone:YES];
        return;
    }

  if (self.onFaultBlock) {
      self.onFaultBlock(fault);
  }
  else if (self.onErrorBlock) {
      // TODO: Convert fault to an NSError?
      self.onErrorBlock(nil);
  }
  else {
      [super onfault:fault];
  }
}

@end
