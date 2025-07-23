@isTest
private class GardenTriggerHandlerTest {

    @testSetup
    static void setupTestUsers() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        insert new User(
            FirstName = 'Old',
            LastName = 'Manager',
            Email = 'manager1230@test.com',
            Username = 'manager1230@test.com',
            Alias = 'oldm',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert new User(
            FirstName = 'New',
            LastName = 'Manager',
            Email = 'manager1231@test.com',
            Username = 'manager1231@test.com',
            Alias = 'newm',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
    }

    @isTest
    static void testBeforeInsert_setsDefaultsAndStatus() {
        User manager = [SELECT Id FROM User WHERE Email = 'manager1230@test.com'];

        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'New Test Garden',
            CAMPX__Manager__c = manager.Id
        );

        insert garden;

        CAMPX__Garden__c inserted = [SELECT Id, CAMPX__Status__c, CAMPX__Capacity__c, CAMPX__Manager_Start_Date__c
                                     FROM CAMPX__Garden__c WHERE Id = :garden.Id];

        System.assertNotEquals(null, inserted.CAMPX__Capacity__c, 'Capacity should be calculated');
        System.assertNotEquals(null, inserted.CAMPX__Status__c, 'Status should be set');
        System.assertNotEquals(null, inserted.CAMPX__Manager_Start_Date__c, 'Manager start date should be set');
    }

    @isTest
    static void testAfterInsert_createsTasks() {
        User manager = [SELECT Id FROM User WHERE Email = 'manager1230@test.com'];

        CAMPX__Garden__c garden = new CAMPX__Garden__c(Name = 'Garden With Tasks', CAMPX__Manager__c = manager.Id);
        insert garden;

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :garden.Id];
        System.assertEquals(1, tasks.size(), 'One task should be created on insert');
    }

    @isTest
    static void testBeforeUpdate_recalculatesStatusAndManagerStart() {
        User manager1 = [SELECT Id FROM User WHERE Email = 'manager1230@test.com'];
        User manager2 = [SELECT Id FROM User WHERE Email = 'manager1231@test.com'];

        CAMPX__Garden__c garden = new CAMPX__Garden__c(Name = 'Update Garden', CAMPX__Manager__c = manager1.Id);
        insert garden;

        Date originalDate = garden.CAMPX__Manager_Start_Date__c;

        garden.CAMPX__Manager__c = manager2.Id;
        garden.CAMPX__Total_Plant_Count__c = 0;
        garden.CAMPX__Capacity__c = 0;

        update garden;

        CAMPX__Garden__c updated = [SELECT CAMPX__Status__c, CAMPX__Manager_Start_Date__c FROM CAMPX__Garden__c WHERE Id = :garden.Id];

        System.assertEquals('Temporary Closure', updated.CAMPX__Status__c);
        System.assertNotEquals(originalDate, updated.CAMPX__Manager_Start_Date__c, 'Start date should be updated on manager change');
    }

    @isTest
    static void testAfterUpdate_createsAndReassignsTasks() {
        User manager1 = [SELECT Id FROM User WHERE Email = 'manager1230@test.com'];
        User manager2 = [SELECT Id FROM User WHERE Email = 'manager1231@test.com'];

        // Insert initial garden and tasks
        CAMPX__Garden__c garden = new CAMPX__Garden__c(Name = 'Transfer Garden', CAMPX__Manager__c = manager1.Id);
        insert garden;

        Task t = new Task(
            Subject = 'Acquire Plants',
            WhatId = garden.Id,
            OwnerId = manager1.Id,
            Status = 'Not Started'
        );
        insert t;

        // Change manager to trigger reassignment
        garden.CAMPX__Manager__c = manager2.Id;
        update garden;

        Task updatedTask = [SELECT OwnerId FROM Task WHERE Id = :t.Id];
        System.assertEquals(manager2.Id, updatedTask.OwnerId, 'Task should be reassigned to new manager');
    }

    @isTest
    static void testAfterUpdate_deletesTasksWhenManagerRemoved() {
        User manager = [SELECT Id FROM User WHERE Email = 'manager1230@test.com'];

        CAMPX__Garden__c garden = new CAMPX__Garden__c(Name = 'Remove Manager', CAMPX__Manager__c = manager.Id);
        insert garden;

        insert new Task(
            Subject = 'Acquire Plants',
            WhatId = garden.Id,
            OwnerId = manager.Id,
            Status = 'Not Started'
        );

        garden.CAMPX__Manager__c = null;
        update garden;

        List<Task> remaining = [SELECT Id FROM Task WHERE WhatId = :garden.Id];
        System.assertEquals(0, remaining.size(), 'Tasks should be deleted when manager is removed');
    }
}
