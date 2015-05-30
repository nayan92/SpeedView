#import <objcipc/objcipc.h>

@interface RootViewController : NSObject {
  double nSpd;
  float UOMfactor;
}
- (void)locationManager:(id)arg1 didUpdateToLocation:(id)arg2 fromLocation:(id)arg3;
@end

%hook RootViewController

- (void)locationManager:(id)arg1
   didUpdateToLocation:(id)arg2
          fromLocation:(id)arg3 {
  %orig;

  double hooked_nSpd = MSHookIvar<double>(self, "nSpd");
  float hooked_UOMfactor = MSHookIvar<float>(self, "UOMfactor");

  int speed = (int) round(hooked_nSpd * hooked_UOMfactor);
  NSDictionary *msgDict = @{@"speed" : [NSNumber numberWithInt:speed]};

  [OBJCIPC sendMessageToSpringBoardWithMessageName:@"com.nayan92.speedview.msg_speedupdate"
                                        dictionary:msgDict
                                        replyHandler:^(NSDictionary *response) {}];
}

%end

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)application {
  %orig;

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(270, 672, 60, 60)];
  window.windowLevel = UIWindowLevelAlert + 2;
  window.layer.cornerRadius = 30;
  window.layer.borderWidth = 5;
  window.layer.borderColor = [[UIColor redColor] CGColor];
  [window setHidden:NO];
  [window setBackgroundColor:[UIColor whiteColor]];

  UILabel *speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
  speedLabel.layer.cornerRadius = 30;
  speedLabel.textAlignment = NSTextAlignmentCenter;
  speedLabel.text = @"N/A";
  [window addSubview:speedLabel];

  [OBJCIPC registerIncomingMessageHandlerForAppWithIdentifier:@"com.pocketgpsworld.CamerAlert"
                                               andMessageName:@"com.nayan92.speedview.msg_speedupdate"
                                                      handler:^NSDictionary *(NSDictionary *message) {
                                                        speedLabel.text = [message[@"speed"] stringValue];
                                                        return nil;
                                                      }];

}

%end
