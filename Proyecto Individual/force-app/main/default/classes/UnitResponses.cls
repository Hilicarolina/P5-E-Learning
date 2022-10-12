public class UnitResponses {

    public static void onBeforeUpdate(List<User_Unit__c>unitRespList,Map<Id,User_Unit__c>oldUnitRespMap){
        List<User_Unit__c> answeredUnitRespList = new List<User_Unit__c>();
        for(User_Unit__c unitResp:unitRespList){
            if(unitResp.Status__c == 'Answered' && oldUnitRespMap.get(unitResp.Id).Status__c == 'Draft'){
                answeredUnitRespList.add(unitResp);
            }
        }
        validateAnswers(answeredUnitRespList);
     
    }
    
     public static void onAfterUpdate(List<User_Unit__c>unitRespList,Map<Id,User_Unit__c>oldUnitRespMap){
        List<User_Unit__c> correctUnitRespList = new List<User_Unit__c>();
        for(User_Unit__c unitResp:unitRespList){
           if(unitResp.Status__c == 'Success'){
                correctUnitRespList.add(unitResp);
            }
        }
         updateUserPoints(correctUnitRespList);
    }
    
    private static void validateAnswers(List<User_Unit__c>unitRespList){
        Boolean verify = false;
        List<User_Unit__c> unitRespFromDb = [SELECT Id,Numbers_Of_Tries__c,Unit__r.Points__c,(SELECT Id,Answer__r.Is_correct__c FROM User_Answers__r) FROM User_Unit__c WHERE Id IN:unitRespList];
        Map<Id,User_Unit__c> unitRespFromDbMap = new Map<Id,User_Unit__c>(unitRespFromDb);
        
        for(User_Unit__c unitResp : unitRespList){
           
            for(User_Answer__c questionResp :unitRespFromDbMap.get(unitResp.id).User_Answers__r){
                unitResp.Status__c = 'Success';
               
                if(!questionResp.Answer__r.Is_correct__c){
                    unitResp.Status__c = 'Fail';
                    break;
                }
            }
            //Seteo de la unidad en la que estamos iterando
            if(unitResp.Status__c == 'Success'){
                if(unitResp.Numbers_Of_Tries__c == 1){
                    unitResp.Points__c = unitRespFromDbMap.get(unitResp.id).Unit__r.Points__c;
                }
                else if(unitResp.Numbers_Of_Tries__c == 2){
                    unitResp.Points__c = unitRespFromDbMap.get(unitResp.id).Unit__r.Points__c/2;
                }else{
                    unitResp.Points__c = unitRespFromDbMap.get(unitResp.id).Unit__r.Points__c/4;
                }
               
            }
        }
        
    }
    
    public static void updateUserPoints(List<User_Unit__c>unitRespList){
        //Seteo del los Ids de usuario por cada unidad respondida
        set<Id>usersIds =new set<Id>();
        for(User_Unit__c unitResp:unitRespList){
            usersIds.add(unitResp.User__c);
        }
        //Buscamos los usuarios asociados a las unidades respondidas en "User-Unit"
        Map<Id,User> usersMap = new Map<Id,User>([SELECT Id,Points__c FROM User WHERE Id in:usersIds]);
       
       //Actualizamos en memoria los puntos de cada usuario en base a las unidades respondidas:
        for(User_Unit__c unitResp: unitRespList){
            User user = usersMap.get(unitResp.User__c);
            user.Points__c = user.Points__c == Null ? unitResp.Points__c : user.Points__c + unitResp.Points__c; 
        }
        update usersMap.values();
    }
 }