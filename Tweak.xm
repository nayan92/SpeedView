#import <objcipc/objcipc.h>

@interface RootViewController : NSObject {
  double nSpd;
}
- (void)locationManager:(id)arg1 didUpdateToLocation:(id)arg2 fromLocation:(id)arg3;
- (void)averageSpeed;
- (void)getServerVersion:(id)arg1;
@end

double hooked_nSpd;

%hook RootViewController

- (void)locationManager:(id)arg1
   didUpdateToLocation:(id)arg2
          fromLocation:(id)arg3 {
  %orig;

  hooked_nSpd = MSHookIvar<double>(self, "nSpd");
  NSLog(@"CamerAlert says speed is %g", hooked_nSpd);
  NSLog(@"We got into method locationManager didUpdateToLocation from Location");

  NSDictionary *msgDict = @{@"speed" : [NSNumber numberWithDouble:hooked_nSpd]};

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
                                                        NSLog(@"Got a message on springboard with value %g", [message[@"speed"] doubleValue]);
                                                        return nil;
                                                      }];


  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(270, 672, 60, 60)];
  window.windowLevel = UIWindowLevelAlert + 2;
  window.layer.cornerRadius = 30;
  window.layer.borderWidth = 5;
  window.layer.borderColor = [[UIColor redColor] CGColor];
  [window setHidden:NO];
  [window setBackgroundColor:[UIColor whiteColor]];
}

%end
