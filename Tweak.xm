#import <objcipc/objcipc.h>
#import <libactivator/libactivator.h>

@interface RootViewController : NSObject {
  double nSpd;
  float nAvg;
  float UOMfactor;
  BOOL isInSpecsZone;
}
- (void)locationManager:(id)arg1 didUpdateToLocation:(id)arg2 fromLocation:(id)arg3;
@end

%hook RootViewController

- (void)locationManager:(id)arg1
   didUpdateToLocation:(id)arg2
          fromLocation:(id)arg3 {
  %orig;

  double hooked_nSpd = MSHookIvar<double>(self, "nSpd");
  float hooked_nAvg = MSHookIvar<float>(self, "nAvg");
  float hooked_UOMfactor = MSHookIvar<float>(self, "UOMfactor");
  BOOL hooked_isInSpecsZone = MSHookIvar<BOOL>(self, "isInSpecsZone");

  int speed = (int) round(hooked_nSpd * hooked_UOMfactor);
  int avgSpeed = (int) round(hooked_nAvg * hooked_UOMfactor);
  NSDictionary *msgDict = @{@"speed" : [NSNumber numberWithInt:speed],
                            @"avgSpeed" : [NSNumber numberWithInt:avgSpeed],
                            @"isInSpecsZone" : [NSNumber numberWithBool:hooked_isInSpecsZone]};

  [OBJCIPC sendMessageToSpringBoardWithMessageName:@"com.nayan92.speedview.msg_speedupdate"
                                        dictionary:msgDict
                                      replyHandler:^(NSDictionary *response) {}];
}

%end

@interface SpeedViewActivator : NSObject<LAListener> {
  BOOL visible;
  UIWindow *window;
  UILabel *speedLabel;
  UILabel *avgSpeedLabel;
  UIView *separator;
  BOOL inAveragingView;
  float firstX;
  float firstY;
}
@end

@implementation SpeedViewActivator

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
  if (visible == YES) {
    window.hidden = YES;
    visible = NO;
  } else {
    if (window == nil)
      [self createWidget];
    window.hidden = NO;
    visible = YES;
  }
}

- (void)registerForIpcEvents {
  NSDictionary *(^onCamerAlertUpdate)(NSDictionary *) = ^NSDictionary *(NSDictionary *message) {
    NSString *speed = [message[@"speed"] stringValue];
    NSString *avgSpeed = [message[@"avgSpeed"] stringValue];
    BOOL isInSpecsZone = [message[@"isInSpecsZone"] boolValue];

    speedLabel.text = speed;
    avgSpeedLabel.text = avgSpeed;

    if (isInSpecsZone && !inAveragingView) {
      inAveragingView = YES;
      [self showAveragingView];
    } else if (!isInSpecsZone && inAveragingView) {
      inAveragingView = NO;
      [self showSpeedOnlyView];
    }

    return nil;
  };

  [OBJCIPC registerIncomingMessageHandlerForAppWithIdentifier:@"com.pocketgpsworld.CamerAlert"
                                               andMessageName:@"com.nayan92.speedview.msg_speedupdate"
                                                      handler:onCamerAlertUpdate];
}

- (void)createWidget {
  window = [[UIWindow alloc] initWithFrame:CGRectMake(270, 672, 60, 60)];
  window.windowLevel = UIWindowLevelAlert + 2;
  window.layer.cornerRadius = 30;
  window.layer.borderWidth = 5;
  window.layer.borderColor = [[UIColor redColor] CGColor];
  [window setHidden:NO];
  [window setBackgroundColor:[UIColor whiteColor]];

  window.userInteractionEnabled = YES;
  UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveAround:)];
  [panRecognizer setMaximumNumberOfTouches:1];
  [panRecognizer setMinimumNumberOfTouches:1];
  [window addGestureRecognizer:panRecognizer];

  speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
  speedLabel.textAlignment = NSTextAlignmentCenter;
  speedLabel.text = @"N/A";
  [window addSubview:speedLabel];

  avgSpeedLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 60, 60)];
  avgSpeedLabel.textAlignment = NSTextAlignmentCenter;
  avgSpeedLabel.text = @"N/A";
  avgSpeedLabel.alpha = 0;
  [window addSubview:avgSpeedLabel];

  separator = [[UIView alloc] initWithFrame:CGRectMake(59, 10, 3, 0)];
  [separator setBackgroundColor:[UIColor blackColor]];
  [window addSubview:separator];
}

- (void)moveAround:(UIPanGestureRecognizer *)gesture {
  if ([gesture state] == UIGestureRecognizerStateBegan) {
    firstX = [window center].x;
    firstY = [window center].y;
  }

  CGPoint translation = [gesture translationInView:window];
  [window setCenter:CGPointMake(firstX + translation.x, firstY + translation.y)];
}

- (void)showAveragingView {
  [UIView animateWithDuration:0.5 animations:^{
    CGRect windowFrame = window.frame;
    windowFrame.size.width = 120;
    window.frame = windowFrame;
  } completion:^(BOOL finished){
    [UIView animateWithDuration:0.5 animations:^{
      avgSpeedLabel.alpha = 1;
      
      CGRect separatorFrame = separator.frame;
      separatorFrame.size.height = 40;
      separator.frame = separatorFrame;
    }];
  }];

  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
  animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  animation.fromValue = @30;
  animation.toValue = @15;
  animation.duration = 0.5;
  [window.layer setCornerRadius:15];
  [window.layer addAnimation:animation forKey:@"cornerRadius"];
}

- (void)showSpeedOnlyView {
  [UIView animateWithDuration:0.5 animations:^{
    avgSpeedLabel.alpha = 0;
    
    CGRect separatorFrame = separator.frame;
    separatorFrame.size.height = 0;
    separator.frame = separatorFrame;
  } completion:^(BOOL finished){
    [UIView animateWithDuration:0.5 animations:^{
      CGRect windowFrame = window.frame;
      windowFrame.size.width = 60;
      window.frame = windowFrame;
    }];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.fromValue = @15;
    animation.toValue = @30;
    animation.duration = 0.5;
    [window.layer setCornerRadius:30];
    [window.layer addAnimation:animation forKey:@"cornerRadius"];
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
