#import <objcipc/objcipc.h>

@interface RootViewController : NSObject {
  //double nSpd;
}
- (void)locationManager:(id)arg1 didUpdateToLocation:(id)arg2 fromLocation:(id)arg3;
- (void)averageSpeed;
- (void)getServerVersion:(id)arg1;
@end

//double hooked_nSpd;

%hook RootViewController

- (void)locationManager:(id)arg1
   didUpdateToLocation:(id)arg2
          fromLocation:(id)arg3 {
  %orig;

 // hooked_nSpd = MSHookIvar<double>(self, "nSpd");
//  NSLog(@"I thing speed is %g", hooked_nSpd);
  NSLog(@"We got into method locationManager didUpdateToLocation from Location");

  NSDictionary *msgDict = @{@"speed" : @10};

  [OBJCIPC sendMessageToSpringBoardWithMessageName:@"com.nayan92.speedview.msg_speedupdate"
                                        dictionary:msgDict
                                        replyHandler:^(NSDictionary *response) {}];
}

%end

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)application {
  %orig;

  NSLog(@"Setup listener");

  [OBJCIPC registerIncomingMessageHandlerForAppWithIdentifier:@"com.pocketgpsworld.CamerAlert"
                                               andMessageName:@"com.nayan92.speedview.msg_speedupdate"
                                                      handler:^NSDictionary *(NSDictionary *message) {
                                                        NSLog(@"Got a message on springboard with value %@", message[@"speed"]);
                                                        return nil;
                                                      }];
}

%end
