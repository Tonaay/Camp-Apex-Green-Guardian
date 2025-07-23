@isTest
public class GardenServiceTest {

    @testSetup
    static void setupData() {
        // Create base garden record used in all tests
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'Test Garden',
            CAMPX__Status__c = '',
            CAMPX__Total_Plant_Count__c = 0,
            CAMPX__Minimum_Plant_Count__c = 0,
            CAMPX__Max_Plant_Count__c = 0,
            CAMPX__Total_Unhealthy_Plant_Count__c = 0,
            CAMPX__Health_Index__c = 0,
            CAMPX__Capacity__c = 0
        );
        insert garden;
    }
    
    // Utility method to create a test User
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.testing',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'GMT'
        );
        insert u;
        return u;
    }

    @isTest
    static void testChangeManagerStartDate() {
        User u = createTestUser();

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User secondUser = new User(
            Alias = 'tuser1',
            Email = 'testuser123@example.com',
            Username = 'testuser123@example.com.testing',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'GMT'
        );

        insert secondUser;

        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'Manager Change Garden',
            CAMPX__Manager__c = u.Id
        );
        insert garden;

        // Simulate manager change by creating a new garden version
        CAMPX__Garden__c updatedGarden = new CAMPX__Garden__c(
            Id = garden.Id,
            CAMPX__Manager__c = secondUser.Id,
            CAMPX__Max_Plant_Count__c = 1
        );

        Map<Id, CAMPX__Garden__c> oldMap = new Map<Id, CAMPX__Garden__c>{
            garden.Id => garden
        };

        Test.startTest();
        GardenService.changeManagerStartDate(new List<CAMPX__Garden__c>{updatedGarden}, oldMap);
        Test.stopTest();

        CAMPX__Garden__c result = [SELECT CAMPX__Manager_Start_Date__c FROM CAMPX__Garden__c WHERE Id = :updatedGarden.Id];
        System.assertNotEquals(null, result.CAMPX__Manager_Start_Date__c);
        System.assertEquals(System.today(), updatedGarden.CAMPX__Manager_Start_Date__c);

    }

    @isTest
    static void testChangeManagerStartDateToNull() {
        User u = createTestUser();

        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'Manager Null Garden',
            CAMPX__Manager__c = u.Id,
            CAMPX__Manager_Start_Date__c = Date.today()
        );
        insert garden;

        // Simulate manager removal
        CAMPX__Garden__c updatedGarden = new CAMPX__Garden__c(
            Id = garden.Id,
            CAMPX__Manager__c = null
        );

        Map<Id, CAMPX__Garden__c> oldMap = new Map<Id, CAMPX__Garden__c>{
            garden.Id => garden
        };

        Test.startTest();
        GardenService.changeManagerStartDate(new List<CAMPX__Garden__c>{updatedGarden}, oldMap);
        Test.stopTest();

        System.assertEquals(null, updatedGarden.CAMPX__Manager_Start_Date__c);
    }

    @isTest
    static void testCalculateCapacity() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'Capacity Garden',
            CAMPX__Max_Plant_Count__c = 200,
            CAMPX__Total_Plant_Count__c = 50
        );

        CAMPX__Garden__c gardenNoPlants = new CAMPX__Garden__c(
            Name = 'Capacity Garden',
            CAMPX__Total_Plant_Count__c = NULL
        );

        CAMPX__Garden__c newClone = garden.clone(true);
        
                // Simulate oldMap where plant count was different
        Map<Id, CAMPX__Garden__c> oldMap = new Map<Id, CAMPX__Garden__c>{
            newClone.Id => newClone.clone(true)
        };

        Test.startTest();
        GardenService.calculateCapacity(new List<CAMPX__Garden__c>{garden}, null);
        GardenService.calculateCapacity(new List<CAMPX__Garden__c>{gardenNoPlants}, null);
        GardenService.calculateCapacity(new List<CAMPX__Garden__c>{newClone}, oldMap);
        Test.stopTest();

        System.assertEquals(25, garden.CAMPX__Capacity__c);
        System.assertEquals(0, gardenNoPlants.CAMPX__Capacity__c);
        System.assertEquals(200, newClone.CAMPX__Max_Plant_Count__c);


    }

    @isTest
    static void testCalculateHealthIndex() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'Health Index Garden',
            CAMPX__Total_Plant_Count__c = 100,
            CAMPX__Total_Unhealthy_Plant_Count__c = 10
        );

        CAMPX__Garden__c newClone = garden.clone(true);
        CAMPX__Garden__c newCloneUnhealthyPlant = garden.clone(true);
        

        Map<Id, CAMPX__Garden__c> oldMap = new Map<Id, CAMPX__Garden__c>{
            garden.Id => garden
        };

        newClone.CAMPX__Total_Plant_Count__c = 10;
        newClone.CAMPX__Total_Unhealthy_Plant_Count__c = 3;
        newCloneUnhealthyPlant.CAMPX__Total_Unhealthy_Plant_Count__c = 3;
            


        Test.startTest();
        GardenService.calculateHealthIndex(new List<CAMPX__Garden__c>{garden}, null);
        GardenService.calculateHealthIndex(new List<CAMPX__Garden__c>{newClone}, oldMap);
        GardenService.calculateHealthIndex(new List<CAMPX__Garden__c>{newCloneUnhealthyPlant}, oldMap);


        Test.stopTest();

        System.assertEquals(90, garden.CAMPX__Health_Index__c);
        System.assertEquals(70, newClone.CAMPX__Health_Index__c);
        System.assertEquals(97, newCloneUnhealthyPlant.CAMPX__Health_Index__c);
    }

    @isTest
    static void testSetGardenStatusAwaitingResources() {
        // Step 1: Create the garden with known values
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'Awaiting Resources Garden',
            CAMPX__Total_Plant_Count__c = 2,
            CAMPX__Capacity__c = 100,
            CAMPX__Max_Plant_Count__c = 10,
            CAMPX__Minimum_Plant_Count__c = 5, // More than current plant count
            CAMPX__Health_Index__c = 80,       // Still good health
            CAMPX__Total_Unhealthy_Plant_Count__c = 0,
            CAMPX__Status__c = 'Operational'
        );
        insert garden;

        // Step 2: Update the garden record to trigger a status change
        CAMPX__Garden__c updatedGarden = new CAMPX__Garden__c(
            Id = garden.Id,
            CAMPX__Total_Plant_Count__c = 2, // still below minimum
            CAMPX__Capacity__c = 60,
            CAMPX__Minimum_Plant_Count__c = 5
        );

        Map<Id, CAMPX__Garden__c> oldMap = new Map<Id, CAMPX__Garden__c>{
            garden.Id => garden
        };

        Test.startTest();
            GardenService.setGardenStatus(new List<CAMPX__Garden__c>{updatedGarden}, oldMap);
        Test.stopTest();

        System.assertEquals('Awaiting Resources', updatedGarden.CAMPX__Status__c);

    }


    @isTest
    static void testSetGardenStatusOperational() {
        // Get garden and simulate available capacity
        CAMPX__Garden__c garden = [SELECT Id, Name, CAMPX__Status__c, CAMPX__Total_Plant_Count__c, CAMPX__Max_Plant_Count__c, 
        CAMPX__Total_Unhealthy_Plant_Count__c, CAMPX__Minimum_Plant_Count__c, CAMPX__Garden__c.CAMPX__Health_Index__c, CAMPX__Capacity__c
        FROM CAMPX__Garden__c LIMIT 1];

        // Simulate oldMap where plant count was different
        Map<Id, CAMPX__Garden__c> oldMap = new Map<Id, CAMPX__Garden__c>{
            garden.Id => garden.clone(true)
        };
        garden.CAMPX__Capacity__c = 80;
        garden.CAMPX__Health_Index__c = 70;
        garden.CAMPX__Total_Plant_Count__c = 3;

        Test.startTest();
        GardenService.setGardenStatus(new List<CAMPX__Garden__c>{garden}, oldMap);
        // update garden;
        Test.stopTest();
        
        System.assertEquals('Operational', garden.CAMPX__Status__c);
    }

    @isTest
    static void testSetGardenStatusTemporaryClosure() {
        // Get garden and simulate temporary closure condition
        CAMPX__Garden__c garden = [SELECT Id, Name, CAMPX__Status__c, CAMPX__Total_Plant_Count__c, CAMPX__Max_Plant_Count__c, 
        CAMPX__Total_Unhealthy_Plant_Count__c, CAMPX__Minimum_Plant_Count__c, CAMPX__Garden__c.CAMPX__Health_Index__c, CAMPX__Capacity__c
        FROM CAMPX__Garden__c LIMIT 1];
        // Simulate old state with 0 unhealthy plants
        CAMPX__Garden__c oldClone = garden.clone(true);
        oldClone.CAMPX__Total_Unhealthy_Plant_Count__c = 0;
        Map<Id, CAMPX__Garden__c> oldMap = new Map<Id, CAMPX__Garden__c>{
            garden.Id => oldClone
        };

        garden.CAMPX__Total_Unhealthy_Plant_Count__c = 5;
        garden.CAMPX__Health_Index__c  = 80;
        garden.CAMPX__Capacity__c = 0;

        Test.startTest();
        GardenService.setGardenStatus(new List<CAMPX__Garden__c>{garden}, oldMap);
        Test.stopTest();

        System.assertEquals('Temporary Closure', garden.CAMPX__Status__c);
    }

    @isTest
    static void testSetGardenStatusPermanentClosure() {
        // Get garden and simulate available capacity
        CAMPX__Garden__c garden = [SELECT Id, Name, CAMPX__Status__c, CAMPX__Total_Plant_Count__c, CAMPX__Max_Plant_Count__c, 
        CAMPX__Total_Unhealthy_Plant_Count__c, CAMPX__Minimum_Plant_Count__c, CAMPX__Garden__c.CAMPX__Health_Index__c, CAMPX__Capacity__c
        FROM CAMPX__Garden__c LIMIT 1];

        CAMPX__Garden__c updatedGarden = garden.clone(true);
        updatedGarden.CAMPX__Status__c = 'Permanent Closure';

        // Simulate oldMap where plant count was different
        Map<Id, CAMPX__Garden__c> oldMap = new Map<Id, CAMPX__Garden__c>{
            garden.Id => garden.clone(true)
        };

        garden.CAMPX__Status__c = 'Permanent Closure';
        
        Map<Id, CAMPX__Garden__c> oldMapPermanentClosure = new Map<Id, CAMPX__Garden__c>{
            updatedGarden.Id => garden.clone(true)
        };

        Test.startTest();
        GardenService.setGardenStatus(new List<CAMPX__Garden__c>{garden}, oldMap);
        GardenService.setGardenStatus(new List<CAMPX__Garden__c>{updatedGarden}, oldMapPermanentClosure);

        // update garden;
        Test.stopTest();
        
        System.assertEquals('Permanent Closure', garden.CAMPX__Status__c);
        System.assertEquals('Permanent Closure', updatedGarden.CAMPX__Status__c);

    }

    @isTest
    static void testSetGardenStatusOverCapacity() {
        // Get garden and simulate temporary closure condition
        CAMPX__Garden__c garden = [SELECT Id, Name, CAMPX__Status__c, CAMPX__Total_Plant_Count__c, CAMPX__Max_Plant_Count__c, 
        CAMPX__Total_Unhealthy_Plant_Count__c, CAMPX__Minimum_Plant_Count__c, CAMPX__Garden__c.CAMPX__Health_Index__c, CAMPX__Capacity__c
        FROM CAMPX__Garden__c LIMIT 1];
        // Simulate old state with 0 unhealthy plants
        CAMPX__Garden__c oldClone = garden.clone(true);
        oldClone.CAMPX__Total_Unhealthy_Plant_Count__c = 0;
        Map<Id, CAMPX__Garden__c> oldMap = new Map<Id, CAMPX__Garden__c>{
            garden.Id => oldClone
        };

        garden.CAMPX__Total_Unhealthy_Plant_Count__c = 5;
        garden.CAMPX__Health_Index__c  = 80;
        garden.CAMPX__Capacity__c = 101;

        Test.startTest();
        GardenService.setGardenStatus(new List<CAMPX__Garden__c>{garden}, oldMap);
        Test.stopTest();

        System.assertEquals('Over Capacity', garden.CAMPX__Status__c);
    }
}
