@isTest
private class GardenTaskServiceTest {

    @testSetup
    static void setupTestData() {
        // Create test users
        List<User> users = new List<User>();
        for (Integer i = 0; i < 2; i++) {
            users.add(new User(
                Alias = 'mgr' + i,
                Email = 'manager123' + i + '@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Manager' + i,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
                TimeZoneSidKey = 'GMT',
                UserName = 'manager123' + i + '@test.com.testing'
            ));
        }
        insert users;

        // Create test gardens
        List<CAMPX__Garden__c> gardens = new List<CAMPX__Garden__c>{
            new CAMPX__Garden__c(Name='Garden 1', CAMPX__Manager__c = users[0].Id),
            new CAMPX__Garden__c(Name='Garden 2', CAMPX__Manager__c = null)
        };
        insert gardens;
    }

    @isTest
    static void testCreateTasksForNewGardens() {
        List<CAMPX__Garden__c> gardens = [SELECT Id, CAMPX__Manager__c FROM CAMPX__Garden__c];
        Test.startTest();
            GardenTaskService.createTasksForNewGardens(gardens);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, WhatId, OwnerId, Subject FROM Task];
        System.assertEquals(2, tasks.size(), 'One task should be created for a garden with a manager.');
        System.assertEquals('Acquire Plants', tasks[0].Subject);
    }

    @isTest
    static void testCreateTasksForNewManagers() {
        // Create a test user to act as the manager
        User manager = new User(
            Alias = 'mgrtest',
            Email = 'manager1231@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'manager1231@test.com' + System.currentTimeMillis() + '@testorg.com'
        );
        insert manager;

        // Create a new garden record without a manager assigned
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'Test Garden No Manager',
            CAMPX__Total_Plant_Count__c = 0,
            CAMPX__Max_Plant_Count__c = 5,
            CAMPX__Capacity__c = 100
        );
        insert garden;

        // Clone the inserted garden to simulate the old state (with no manager)
        CAMPX__Garden__c oldGarden = garden.clone(false, false, false, false);
        oldGarden.Id = garden.Id;  // Set the Id so it matches the map key

        // Now assign a manager and update the garden
        garden.CAMPX__Manager__c = manager.Id;
        update garden;

        // Prepare the inputs for the service method
        List<CAMPX__Garden__c> newList = new List<CAMPX__Garden__c>{garden};
        Map<Id, CAMPX__Garden__c> oldMap = new Map<Id, CAMPX__Garden__c>{oldGarden.Id => oldGarden};

        Test.startTest();
            GardenTaskService.createTasksForNewManagers(newList, oldMap);
        Test.stopTest();

        // Verify a Task was created with the correct owner and WhatId
        List<Task> tasks = [SELECT Id, OwnerId, WhatId, Subject FROM Task WHERE OwnerId = :manager.Id AND WhatId = :garden.Id];
        System.assertEquals(2, tasks.size(), 'One task should be created for the newly assigned manager.');
        System.assertEquals('Acquire Plants', tasks[0].Subject);
    }

    @isTest
    static void testReassignTasksToNewManager() {
        // Create old and new test managers
        User oldManager = new User(
            Alias = 'oldmgr',
            Email = 'manager1230@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Old Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'manager1230_' + System.currentTimeMillis() + '@test.com'
        );
        User newManager = new User(
            Alias = 'newmgr',
            Email = 'manager1231@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'New Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = oldManager.ProfileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'manager1231_' + System.currentTimeMillis() + '@test.com'
        );
        insert new List<User>{oldManager, newManager};

        // Create a garden and task assigned to old manager
        CAMPX__Garden__c garden = new CAMPX__Garden__c(Name = 'Transfer Garden', CAMPX__Manager__c = oldManager.Id);
        insert garden;

        Task task = new Task(
            Subject = 'Acquire Plants',
            WhatId = garden.Id,
            OwnerId = oldManager.Id,
            Status = 'Not Started',
            Priority = 'Normal'
        );
        insert task;

        // Clone garden for oldMap and update to new manager
        CAMPX__Garden__c oldGarden = garden.clone(false, false, false, false);
        oldGarden.Id = garden.Id;
        garden.CAMPX__Manager__c = newManager.Id;
        update garden;

        Test.startTest();
            GardenTaskService.reassignTasksToNewManager(
                new List<CAMPX__Garden__c>{garden},
                new Map<Id, CAMPX__Garden__c>{garden.Id => oldGarden}
            );
        Test.stopTest();

        Task updatedTask = [SELECT Id, OwnerId FROM Task WHERE Id = :task.Id];
        System.assertEquals(newManager.Id, updatedTask.OwnerId, 'Task should be reassigned to new manager.');
    }

    @isTest
    static void testDeleteTasksForUnassignedManagers() {
        // Create a manager
        User manager = new User(
            Alias = 'delmgr',
            Email = 'manager1230@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Delete Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'manager1230_' + System.currentTimeMillis() + '@test.com'
        );
        insert manager;

        // Create garden and associated task
        CAMPX__Garden__c garden = new CAMPX__Garden__c(Name = 'Delete Garden', CAMPX__Manager__c = manager.Id);
        insert garden;

        Task task = new Task(
            Subject = 'Acquire Plants',
            WhatId = garden.Id,
            OwnerId = manager.Id,
            Status = 'Not Started',
            Priority = 'Normal'
        );
        insert task;

        // Clone garden for oldMap and simulate unassigning the manager
        CAMPX__Garden__c oldGarden = garden.clone(false, false, false, false);
        oldGarden.Id = garden.Id;
        garden.CAMPX__Manager__c = null;
        update garden;

        Test.startTest();
            GardenTaskService.deleteTasksForUnassignedManagers(
                new List<CAMPX__Garden__c>{garden},
                new Map<Id, CAMPX__Garden__c>{garden.Id => oldGarden}
            );
        Test.stopTest();

        List<Task> remainingTasks = [SELECT Id FROM Task WHERE WhatId = :garden.Id];
        System.assertEquals(0, remainingTasks.size(), 'Task should be deleted when manager is unassigned.');
    }

}
