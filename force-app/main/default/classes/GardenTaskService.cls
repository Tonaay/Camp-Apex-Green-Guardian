public with sharing class GardenTaskService {

    public static void createTasksForNewGardens(List<CAMPX__Garden__c> gardens) {
        List<Task> tasksToInsert = new List<Task>();

        for (CAMPX__Garden__c garden : gardens) {
            if (garden.CAMPX__Manager__c != null) {
                Task t = new Task(
                    Subject = 'Acquire Plants',
                    WhatId = garden.Id,
                    OwnerId = garden.CAMPX__Manager__c,
                    Status = 'Not Started', // Optional: you can customise more fields here
                    Priority = 'Normal'
                );
                tasksToInsert.add(t);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    public static void createTasksForNewManagers(
        List<CAMPX__Garden__c> newList,
        Map<Id, CAMPX__Garden__c> oldMap
    ) {
        List<Task> tasksToInsert = new List<Task>();

        for (CAMPX__Garden__c newRec : newList) {
            CAMPX__Garden__c oldRec = oldMap.get(newRec.Id);

            Boolean managerWasBlank = oldRec.CAMPX__Manager__c == null;
            Boolean managerNowSet   = newRec.CAMPX__Manager__c != null;

            if (managerWasBlank && managerNowSet) {
                Task t = new Task(
                    Subject = 'Acquire Plants',
                    WhatId = newRec.Id,
                    OwnerId = newRec.CAMPX__Manager__c,
                    Status = 'Not Started',
                    Priority = 'Normal'
                );
                tasksToInsert.add(t);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    public static void reassignTasksToNewManager(
        List<CAMPX__Garden__c> newList,
        Map<Id, CAMPX__Garden__c> oldMap
    ) {
        Map<Id, Id> gardenToNewManager = new Map<Id, Id>();
        Map<Id, Id> gardenToOldManager = new Map<Id, Id>();

        for (CAMPX__Garden__c newRec : newList) {
            CAMPX__Garden__c oldRec = oldMap.get(newRec.Id);

            // Check if manager has changed
            if (newRec.CAMPX__Manager__c != null &&
                oldRec.CAMPX__Manager__c != null &&
                newRec.CAMPX__Manager__c != oldRec.CAMPX__Manager__c) {

                gardenToNewManager.put(newRec.Id, newRec.CAMPX__Manager__c);
                gardenToOldManager.put(newRec.Id, oldRec.CAMPX__Manager__c);
            }
        }

        if (gardenToNewManager.isEmpty()) return;

        List<Task> tasksToUpdate = [
            SELECT Id, OwnerId, WhatId, Subject, Status
            FROM Task
            WHERE WhatId IN :gardenToNewManager.keySet()
                AND Subject = 'Acquire Plants'
                AND Status != 'Completed'
                AND OwnerId IN :gardenToOldManager.values()
        ];

        for (Task t : tasksToUpdate) {
            // Double check old OwnerId matches expected
            Id expectedOldOwner = gardenToOldManager.get(t.WhatId);
            if (t.OwnerId == expectedOldOwner) {
                t.OwnerId = gardenToNewManager.get(t.WhatId);
            }
        }

        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
    }

    public static void deleteTasksForUnassignedManagers(
        List<CAMPX__Garden__c> newList,
        Map<Id, CAMPX__Garden__c> oldMap
    ) {
        Map<Id, Id> gardenToOldManager = new Map<Id, Id>();

        for (CAMPX__Garden__c newRec : newList) {
            CAMPX__Garden__c oldRec = oldMap.get(newRec.Id);
            if (newRec.CAMPX__Manager__c == null && oldRec.CAMPX__Manager__c != null) {
                gardenToOldManager.put(newRec.Id, oldRec.CAMPX__Manager__c);
            }
        }

        if (!gardenToOldManager.isEmpty()) {
            List<Task> potentialTasks = [
                SELECT Id, WhatId, OwnerId, Subject, Status
                FROM Task
                WHERE WhatId IN :gardenToOldManager.keySet()
                AND Subject = 'Acquire Plants'
                AND Status != 'Completed'
            ];

            List<Task> tasksToDelete = new List<Task>();
            for (Task t : potentialTasks) {
                if (gardenToOldManager.get(t.WhatId) == t.OwnerId) {
                    tasksToDelete.add(t);
                }
            }

            if (!tasksToDelete.isEmpty()) {
                delete tasksToDelete;
            }
        }
    }
}