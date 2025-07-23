public with sharing class GardenTriggerHandler {
    public static void handle(List<CAMPX__Garden__c> newList, Map<Id, CAMPX__Garden__c> oldMap) {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                GardenDefaultsService.initializeDefaults(newList);
                GardenService.changeManagerStartDate(newList, NULL);
                GardenService.calculateCapacity(newList, null);
                GardenService.calculateHealthIndex(newList, null);
                GardenService.setGardenStatus(newList, null);
            }

            if (Trigger.isUpdate){
                GardenService.changeManagerStartDate(newList, oldMap);
                GardenService.calculateCapacity(newList, oldMap);
                GardenService.calculateHealthIndex(newList, oldMap);
                GardenService.setGardenStatus(newList, oldMap);

            }
        }

        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                GardenTaskService.createTasksForNewGardens(newList);
            }

            if (Trigger.isUpdate) {
                GardenTaskService.createTasksForNewManagers(newList, oldMap);
                GardenTaskService.reassignTasksToNewManager(newList, oldMap);
                GardenTaskService.deleteTasksForUnassignedManagers(newList, oldMap);
            }
        }
    }
}