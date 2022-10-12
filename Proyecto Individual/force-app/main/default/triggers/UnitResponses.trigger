trigger UnitResponses on User_Unit__c (before update, after update) {
    if(Trigger.isBefore){
        UnitResponses.onBeforeUpdate(Trigger.New,Trigger.oldMap);
    }else{
        UnitResponses.onAfterUpdate(Trigger.New,Trigger.oldMap);
    }
    
}