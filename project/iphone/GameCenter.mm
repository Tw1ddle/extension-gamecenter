#include <GameCenter.h>

// Some transitive includes complain if these are not defined
#define __ARM_NEON 1
#define __ARM_NEON__ 1

#import <CoreFoundation/CoreFoundation.h>
#import <GameKit/GameKit.h>
#import <UIKit/UIKit.h>

#define __STDC_FORMAT_MACROS // non needed in C, only in C++
#include <inttypes.h>

extern "C" void sendGameCenterEvent (const char* event, const char* data1, const char* data2, const char* data3, const char* data4);

typedef void (*FunctionType)();

@interface GKViewDelegate : NSObject <GKAchievementViewControllerDelegate,GKLeaderboardViewControllerDelegate> {}
	- (void)achievementViewControllerDidFinish:(GKAchievementViewController*)viewController;
	- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController*)viewController;
@end

@implementation GKViewDelegate
	- (id)init {
		self = [super init];
		return self;
	}
	
	- (void)dealloc {
		[super dealloc];
	}
	
	UIViewController *glView2;
	
	- (void)achievementViewControllerDidFinish:(GKAchievementViewController*)viewController {
		[viewController dismissModalViewControllerAnimated:YES];
		[viewController.view.superview removeFromSuperview];
		[viewController release];
	}
	
	- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController*)viewController {
		[viewController dismissModalViewControllerAnimated:YES];
		[viewController.view.superview removeFromSuperview];
		[viewController release];
	}
@end

namespace gamecenter {
	static int isInitialized = 0;
	GKViewDelegate* viewDelegate;
	
	void initializeGameCenter ();
	bool isGameCenterAvailable ();
	bool isUserAuthenticated ();
	void authenticateLocalUser ();
	
	const char* getPlayerName ();
	const char* getPlayerID ();

	void showLeaderboard (const char* categoryID);
	void reportScore (const char* categoryID, int score);

	void showAchievements ();
	void resetAchievements ();
	void reportAchievement (const char* achievementID, float percent, bool showCompletionBanner);

	static const char* DISABLED = "disabled";
	static const char* AUTH_SUCCESS = "authSuccess";
	static const char* AUTH_ALREADY = "authAlready";
	static const char* AUTH_FAILURE = "authFailure";
	static const char* SCORE_SUCCESS = "scoreSuccess";
	static const char* SCORE_FAILURE = "scoreFailure";
	static const char* ACHIEVEMENT_SUCCESS = "achievementSuccess";
	static const char* ACHIEVEMENT_FAILURE = "achievementFailure";
	static const char* ACHIEVEMENT_RESET_SUCCESS = "achievementResetSuccess";
	static const char* ACHIEVEMENT_RESET_FAILURE = "achievementResetFailure";

	static const char* ON_GET_ACHIEVEMENT_STATUS_FAILURE = "onGetAchievementStatusFailure";
	static const char* ON_GET_ACHIEVEMENT_STATUS_SUCCESS = "onGetAchievementStatusSuccess";
	static const char* ON_GET_ACHIEVEMENT_PROGRESS_FAILURE = "onGetAchievementProgressFailure"; 
	static const char* ON_GET_ACHIEVEMENT_PROGRESS_SUCCESS = "onGetAchievementProgressSuccess";
	static const char* ON_GET_PLAYER_SCORE_FAILURE = "onGetPlayerScoreFailure";
	static const char* ON_GET_PLAYER_SCORE_SUCCESS = "onGetPlayerScoreSuccess";

	void initializeGameCenter () {
		if (isInitialized == 1) {
			return;
		}
		
		if (isGameCenterAvailable ()) {
			viewDelegate = [[GKViewDelegate alloc] init];
			isInitialized = 1;
			authenticateLocalUser ();
		}
	}
	
	bool isGameCenterAvailable () {
		// check if the device is running iOS 4.1 or later  
		NSString* reqSysVer = @"4.1";   
		NSString* currSysVer = [[UIDevice currentDevice] systemVersion];   
		BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);   

		NSLog(@"Game Center is available");
		return (osVersionSupported);
	}
	
	bool isUserAuthenticated () {
		return ([GKLocalPlayer localPlayer].isAuthenticated);
	}
	
	void authenticateLocalUser () {
		if (!isGameCenterAvailable ()) {
			NSLog (@"Game Center: is not available");
			sendGameCenterEvent (DISABLED, "", "", "", "");
			return;
		}
		
		NSLog (@"Authenticating local user...");
		
		if ([GKLocalPlayer localPlayer].authenticated == NO) {
			
			@try {
			
				NSLog(@"Will try to authenticate player");
			
				GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];

				localPlayer.authenticateHandler = ^(UIViewController* viewcontroller, NSError *error) {
				
					if (localPlayer.isAuthenticated) {
					
						NSLog (@"Game Center: You are logged in to game center.");

					} else if (viewcontroller != nil) {
					
						NSLog (@"Game Center: User was not logged in. Show Login Screen.");
						UIViewController *glView2 = [[[UIApplication sharedApplication] keyWindow] rootViewController];
						[glView2 presentModalViewController: viewcontroller animated : NO];
					
					} else if (error != nil) {
					
						NSLog (@"Game Center: Error occurred authenticating-");
						NSLog (@"  %@", [error localizedDescription]);
						NSString* errorDescription = [error localizedDescription];
						sendGameCenterEvent (AUTH_FAILURE, [errorDescription UTF8String], "", "", "");
					
					}
				
				};
				
			}
   		    @catch (NSException *exception){
  		    	NSLog(@"authenticateLocalPlayer Caught an exception");
  		  	}
  			@finally {
				NSLog(@"authenticateLocalPlayer Cleaning up");
			}
		} else {
			NSLog (@"Already authenticated!");
			sendGameCenterEvent (AUTH_ALREADY, "", "", "", "");
		}
	}
	
	const char* getPlayerName () {
		
		GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
		
		if (localPlayer.isAuthenticated) {
			
			return [localPlayer.alias cStringUsingEncoding:NSUTF8StringEncoding];
			
		} else {
			
			return NULL;
			
		}
		
	}
	
	const char* getPlayerID () {
		GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
		if (localPlayer.isAuthenticated) {
			return [localPlayer.playerID cStringUsingEncoding:NSUTF8StringEncoding];
		} else {
			return NULL;
		}
	}
	
	void showLeaderboard (const char* categoryID) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSString* strCategory = [[NSString alloc] initWithUTF8String:categoryID];
		UIWindow* window = [UIApplication sharedApplication].keyWindow;
		GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];  
		
		if (leaderboardController != nil) {
			leaderboardController.category = strCategory;
			leaderboardController.leaderboardDelegate = viewDelegate;
			UIViewController *glView2 = [[[UIApplication sharedApplication] keyWindow] rootViewController];
			[glView2 presentModalViewController:leaderboardController animated: NO];
		}
		
		[strCategory release];
		[pool drain];
	}
	
	void reportScore (const char* categoryID, int score) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSString* strCategory = [[NSString alloc] initWithUTF8String:categoryID];
		GKScore* scoreReporter = [[[GKScore alloc] initWithCategory:strCategory] autorelease];
		
		if (scoreReporter) {
			scoreReporter.value = score;
			[scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
				if (error != nil) {
					NSLog (@"Game Center: Error occurred reporting score-");
					NSLog (@"  %@", [error userInfo]);
					sendGameCenterEvent (SCORE_FAILURE, categoryID, "", "", "");
				} else {
					NSLog (@"Game Center: Score was successfully sent");
					sendGameCenterEvent (SCORE_SUCCESS, categoryID, "", "", "");
				}
			}];
		}
        
		[strCategory release];
		[pool drain];
	}
	
	void getPlayerScore(const char* leaderboardID) {

		NSString* strLeaderboard = [[NSString alloc] initWithUTF8String:leaderboardID];
		GKLeaderboard* leaderboardRequest = [[GKLeaderboard alloc] init];
		leaderboardRequest.identifier = strLeaderboard;
		
		[leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
			if (error != nil) {
				// Handle the error.
				NSLog (@"Game Center: Error occurred getting score-");
				NSLog (@"  %@", [error userInfo]);				
				sendGameCenterEvent (ON_GET_PLAYER_SCORE_FAILURE, leaderboardID, "", "", "");
			}
			if (scores != nil) {
				// Process the score information.
				GKScore* localPlayerScore = leaderboardRequest.localPlayerScore;
				NSString* myString = [NSString stringWithFormat:@"%lld", localPlayerScore.value];
				NSLog (@"Game Center: Player score was successfully obtained");
				sendGameCenterEvent (ON_GET_PLAYER_SCORE_SUCCESS, leaderboardID, [myString UTF8String], "", "");			
			}
		}];
		[strLeaderboard release];	
	}

	void showAchievements () {
		NSLog(@"Game Center: Show Achievements");
		UIWindow* window = [UIApplication sharedApplication].keyWindow;
		GKAchievementViewController* achievements = [[GKAchievementViewController alloc] init]; 
		
		if (achievements != nil) {
			achievements.achievementDelegate = viewDelegate;
			UIViewController *glView2 = [[[UIApplication sharedApplication] keyWindow] rootViewController];
			[glView2 presentModalViewController: achievements animated: NO];
		}
	}
	
	void resetAchievements () {
		[GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
			if (error != nil) {
				NSLog (@"  %@", [error userInfo]);
				sendGameCenterEvent (ACHIEVEMENT_RESET_FAILURE, "", "", "", "");
			} else {
				sendGameCenterEvent(ACHIEVEMENT_RESET_SUCCESS, "", "", "", "");
			}
		}];
	}
	
	void reportAchievement (const char* achievementID, float percentComplete, bool showCompletionBanner) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSString* strAchievement = [[NSString alloc] initWithUTF8String:achievementID];
		NSLog (@"Game Center: Report Achievements");
		NSLog (@"  %@", strAchievement);
		GKAchievement* achievement = [[[GKAchievement alloc] initWithIdentifier:strAchievement] autorelease];
		
		if (achievement) {
			achievement.percentComplete = percentComplete;    
			achievement.showsCompletionBanner = showCompletionBanner;
			
			[achievement reportAchievementWithCompletionHandler:^(NSError *error) {
				if (error != nil) {
					NSLog (@"Game Center: Error occurred reporting achievement-");
					NSLog (@"  %@", [error userInfo]);
					sendGameCenterEvent (ACHIEVEMENT_FAILURE, achievementID, "", "", "");
				} else {
					NSLog (@"Game Center: Achievement report successfully sent");
					sendGameCenterEvent (ACHIEVEMENT_SUCCESS, achievementID, "", "", "");
				}
			}];
		} else {
			sendGameCenterEvent (ACHIEVEMENT_FAILURE, achievementID, "", "", "");
		}
		
		[strAchievement release];
		[pool drain];
	}
	
	void getAchievementProgress(const char* achievementID) {
		NSString* strAchievementInput = [[NSString alloc] initWithUTF8String:achievementID];

		[GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
			if (error != nil) {
				NSLog (@"Game Center: Error occurred getting achievements array-");
				NSLog (@"  %@", [error userInfo]);				
				sendGameCenterEvent (ON_GET_ACHIEVEMENT_PROGRESS_FAILURE, achievementID, "", "", "");
			}
			if (achievements != nil) {
				// Process the array of achievements.
				for (GKAchievement* achievement in achievements) {
					if ([achievement.identifier isEqualToString:strAchievementInput]) {
						NSString* myString = [NSString stringWithFormat:@"%.2f", achievement.percentComplete];
						NSLog (@"Game Center: Achievement percent was successfully obtained");
						sendGameCenterEvent (ON_GET_ACHIEVEMENT_PROGRESS_SUCCESS, achievementID, [myString UTF8String], "", "");
						return;
					}
				}
			}
		}];
	}

	void getAchievementStatus(const char* achievementID) {
		NSString* strAchievementInput = [[NSString alloc] initWithUTF8String:achievementID];

		[GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
			if (error != nil) {
				NSLog (@"Game Center: Error occurred getting achievements array-");
				NSLog (@"  %@", [error userInfo]);				
				sendGameCenterEvent (ON_GET_ACHIEVEMENT_STATUS_FAILURE, achievementID, "", "", "");
			}
			if (achievements != nil) {
				// Process the array of achievements.
				for (GKAchievement* achievement in achievements) {
					if ([achievement.identifier isEqualToString:strAchievementInput]) {
						if (achievement.completed) {
							NSLog (@"Game Center: Achievement status was successfully obtained");
							NSString* status = @"Completed";
							sendGameCenterEvent (ON_GET_ACHIEVEMENT_STATUS_SUCCESS, achievementID, [status UTF8String], "", "");
						} else {
							NSLog (@"Game Center: Achievement status was successfully obtained");
							NSString* status = @"Not Completed";
							sendGameCenterEvent (ON_GET_ACHIEVEMENT_STATUS_SUCCESS, achievementID, [status UTF8String], "", "");
						}
					}
					return;
				}
			}
		}];
	}
}
