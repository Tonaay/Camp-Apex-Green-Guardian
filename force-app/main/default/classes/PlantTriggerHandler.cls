public with sharing class PlantTriggerHandler {
    public static void handle(List<CAMPX__Plant__c> newList, Map<Id, CAMPX__Plant__c> oldMap) {

        if(Trigger.isBefore){
            if(Trigger.isInsert){
                PlantDefaultsService.initializeDefaults(newList);
            }
        }

        if (Trigger.isAfter) {
            List<CAMPX__Plant__c> oldList = (Trigger.isInsert) ? null : Trigger.old;
            PlantGardenService.syncPlantCounts(newList, oldList);
            PlantGardenService.syncUnhealthyPlantCount(newList, oldList);
        }

        if (Trigger.isAfter && Trigger.isDelete) {
            PlantGardenService.syncPlantCounts(new List<CAMPX__Plant__c>(), Trigger.old);
            PlantGardenService.syncUnhealthyPlantCount(new List<CAMPX__Plant__c>(), Trigger.old);
        }

    }
}
