#import "MainAppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface MainAppDelegate ()
@property AVPlayerLayer *playerLayer;
@end

@implementation MainAppDelegate

- (id)init
{
	self = [super init];
	
	// Create animationWindow
	realAnimationWindow =
    [[NSWindow alloc] initWithContentRect:NSZeroRect
                                styleMask:NSBorderlessWindowMask
                                  backing:NSBackingStoreBuffered
                                    defer:NO];
	
	return self;
}

- (void)setupAnimationWindowWithHidden:(BOOL)hidden
{
    CGFloat alphaValue = 1.0;
    if (hidden) {
        alphaValue = 0.0;
    }
    
    // show animation window
    [realAnimationWindow setLevel:NSScreenSaverWindowLevel];
    
    [realAnimationWindow setFrame:[[[NSScreen screens] objectAtIndex:0] frame] display:YES];
    
    [strip setLevel:NSScreenSaverWindowLevel];
    [strip orderWindow:NSWindowAbove relativeTo:[[stars window] windowNumber]];
    
    // create a
    NSRect stripRect = NSMakeRect(0.0, (NSHeight([[[NSScreen screens] objectAtIndex:0] frame]) / 2 - 103.0), NSWidth([[[NSScreen screens] objectAtIndex:0] frame]), 206.0);
    
    [strip setFrame:stripRect display:YES];
    
    NSRect newFrame = NSMakeRect(0.0, 0.0,
                                 NSWidth([[[NSScreen screens] objectAtIndex:0] frame]),
                                 NSHeight([[[NSScreen screens] objectAtIndex:0] frame]));
    [stars setFrame:newFrame];
    
    // update video layer
    [self.playerLayer setFrame:newFrame];
    
    [realAnimationWindow makeKeyAndOrderFront:self];
    [realAnimationWindow setAlphaValue:alphaValue];
    
    [strip makeKeyAndOrderFront:self];
    [strip setAlphaValue:alphaValue];
}

- (IBAction)runEffect:(id)sender
{
	// get a list of the applications currently launched
	NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
	
    for (NSRunningApplication *app in runningApps) {
        if (![currentApps containsObject:app]) {
			if ([_checkbox state] == NSOnState) {
                
				// set label to app name
				[appName setStringValue:[app localizedName]];
				
				// create new NSImage from that app's icon
				NSImage *icon = [app icon];
				[icon setSize:NSMakeSize(128.0,128.0)];
				
				[iconView setImage: icon];
				
				// play sound
				[mySound play];
                
                [stars.player seekToTime:CMTimeMakeWithSeconds(0.0f, NSEC_PER_SEC) toleranceBefore: kCMTimeZero toleranceAfter: kCMTimeZero];
                
                [self setupAnimationWindowWithHidden:NO];
                
				[stars.player play];
                
			}
		}
    }
    
	currentApps = runningApps;
}

- (void)endEffect
{
	timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                            target:self
                                            selector:@selector(fadeEffectOut)
                                            userInfo:nil
                                            repeats:YES];
}

- (void)fadeEffectOut
{
	if ([realAnimationWindow alphaValue] > 0.0) {
		[realAnimationWindow setAlphaValue:([realAnimationWindow alphaValue] - 0.1)];
		[strip setAlphaValue:([strip alphaValue] - 0.1)];
	} else {
		[timer invalidate];
	}
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool
{
	if (aBool) {
		[stars.player pause];
		// when sound is done, endEffect
		[self endEffect];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	mySound = [NSSound soundNamed:@"effect_sound"];
	[mySound setDelegate:self];
	
	// Get notification center
	notCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	
	// get a list of all currently running applications
	currentApps = [[NSWorkspace sharedWorkspace] runningApplications];
	
	// sign up for notifications when applications launch
	[notCenter addObserver:self
                  selector:@selector(runEffect:)
                      name:NSWorkspaceDidLaunchApplicationNotification
                    object:nil]; // Register for all notifications
	
	NSView *view = [animationWindow contentView];
	[animationWindow setContentView:nil];
	[realAnimationWindow setContentView:view];
	
	// create movie
	NSString *pathToMovie = [[NSBundle mainBundle] pathForResource:@"stars2" ofType:@"mov"];

    myMoviePlayer = [[AVPlayer alloc] initWithURL:
                     [NSURL fileURLWithPath: pathToMovie]];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:myMoviePlayer];
    [stars setWantsLayer:YES];
    [stars.layer addSublayer:self.playerLayer];
    [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

    
	// set movie to movie view
    stars.player = myMoviePlayer;
    
	[strip setAlphaValue:0.0];
    [strip setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"strip.png"]]];

	[strip orderWindow:NSWindowAbove relativeTo:[[stars window] windowNumber]];
	
    [_window makeKeyAndOrderFront:self];
	
    [self setupAnimationWindowWithHidden:YES];
    
    return;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender
                    hasVisibleWindows:(BOOL)flag;
{
	[_window makeKeyAndOrderFront:self];
	[strip makeKeyAndOrderFront:self];
	
	return YES;
}

@end
