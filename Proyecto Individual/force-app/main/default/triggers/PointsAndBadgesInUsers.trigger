trigger PointsAndBadgesInUsers on User (before update) {
  PointsAndBadgesInUsers.onBeforeUpdate(Trigger.New,Trigger.oldMap);
    
}