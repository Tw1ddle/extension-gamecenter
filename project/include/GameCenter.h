#ifndef GAME_CENTER_H
#define GAME_CENTER_H

namespace gamecenter 
{
	void initializeGameCenter();
    bool isGameCenterAvailable();
	bool isUserAuthenticated();
    void authenticateLocalUser();
    
    const char* getPlayerName();
    const char* getPlayerID();
    
    void showLeaderboard(const char* categoryID);
    void reportScore(const char* categoryID, int score);
    void getPlayerScore(const char* leaderboardID);
    
    void showAchievements();
    void resetAchievements();
    void reportAchievement(const char* achievementID, float percent, bool showCompletionBanner);
    void getAchievementProgress(const char* achievementID);
    void getAchievementStatus(const char* achievementID);

    void registerForAuthenticationNotification();
}

#endif
