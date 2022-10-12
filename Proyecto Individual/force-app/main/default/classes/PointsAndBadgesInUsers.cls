public class PointsAndBadgesInUsers {
    public static void onBeforeUpdate(List<User>userList,Map<Id,User>oldUserMap){
       List<User> users = new List<User>();
       for(User user:userList){
            if(user.Points__c != oldUserMap.get(user.id).Points__c){
                users.add(user);
            }
        }
        updatePointsAndBadges(userList);
   }
    private static void updatePointsAndBadges(List<User>userList){
        Map<Id,User>userListFromDb = new Map<Id,User>([SELECT Id, (SELECT Id, Status__c FROM User_Modules__r WHERE Status__c='Completed') FROM User WHERE Id=:userList]);
        for(User user:userList){
            //Cálculo de Número de Badges:
            user.Badges__c = userListFromDb.get(user.Id).User_Modules__r.size();
            //Seteo de Rank:
            rankCalculation(user);
        }
    }
    private static void rankCalculation(User user){
        if(0 <= user.Points__c  && user.Points__c < 200 || user.Points__c== Null){
                user.Rank__c ='SCOUT';
        }else if(200 <=user.Points__c && user.Points__c < 3000){
                user.Rank__c ='HIKER';
        }else if(3000 <=user.Points__c && user.Points__c < 9000){
                user.Rank__c ='EXPLORER';
        }else if(9000 <=user.Points__c && user.Points__c < 18000){
                user.Rank__c ='ADVENTURER';
        }else if(18000 <=user.Points__c && user.Points__c < 35000){
                     user.Rank__c ='MOUNTAINEER';
        }else if(35000 <=user.Points__c && user.Points__c < 50000){
                     user.Rank__c ='EXPEDITIONER';
        }else{
                user.Rank__c ='RANGER';
        }
        
   }
}