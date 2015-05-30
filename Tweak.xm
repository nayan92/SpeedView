#import <objcipc/objcipc.h>
#import <libactivator/libactivator.h>


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

@interface SpeedViewActivator : NSObject<LAListener> {
  BOOL visible;
  UIWindow *window;
  UILabel *speedLabel;
}
@end

@implementation SpeedViewActivator

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
  if (visible == YES) {
    window.hidden = YES;
    visible = NO;
  } else {
    if (window == nil)
      [self displaySpeedometer];
    window.hidden = NO;
    visible = YES;
  }
}

- (void)displaySpeedometer {
  window = [[UIWindow alloc] initWithFrame:CGRectMake(270, 672, 60, 60)];
  window.windowLevel = UIWindowLevelAlert + 2;
  window.layer.cornerRadius = 30;
  window.layer.borderWidth = 5;
  window.layer.borderColor = [[UIColor redColor] CGColor];
  [window setHidden:NO];
  [window setBackgroundColor:[UIColor whiteColor]];

  speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
  speedLabel.layer.cornerRadius = 30;
  speedLabel.textAlignment = NSTextAlignmentCenter;
  speedLabel.text = @"N/A";
  [window addSubview:speedLabel];
}

- (void)registerForIpcEvents {
  [OBJCIPC registerIncomingMessageHandlerForAppWithIdentifier:@"com.pocketgpsworld.CamerAlert"
                                               andMessageName:@"com.nayan92.speedview.msg_speedupdate"
                                                      handler:^NSDictionary *(NSDictionary *message) {
                                                        if (speedLabel != nil)
                                                          speedLabel.text = [message[@"speed"] stringValue];
                                                        return nil;
                                                      }];
}

+ (void)load {
  if ([LASharedActivator isRunningInsideSpringBoard]) {
    SpeedViewActivator * me = [self new];
    [LASharedActivator registerListener:me forName:@"com.nayan92.speedview"];
    [me registerForIpcEvents];
  }
}

@end
