@isTest
private class GardenDefaultServiceTest {
    
    @isTest
    static void testInitializeDefaults_appliesExpectedDefaults() {

        CAMPX__Garden__c testGarden = new CAMPX__Garden__c(
            Name = 'Test Garden'
        );
        
        List<CAMPX__Garden__c> gardenList = new List<CAMPX__Garden__c>{ testGarden };

        Test.startTest();
        GardenDefaultsService.initializeDefaults(gardenList);
        Test.stopTest();

        System.assertEquals('Awaiting Resources', testGarden.CAMPX__Status__c, 'Expected status to be Awaiting Resources');
        System.assertEquals(100, testGarden.CAMPX__Max_Plant_Count__c, 'Expected default max plant count to be 100');
        System.assertEquals(1, testGarden.CAMPX__Minimum_Plant_Count__c, 'Expected default minimum plant count to be 1');
        System.assertEquals(0, testGarden.CAMPX__Total_Plant_Count__c, 'Expected default total plant count to be 0');
        System.assertEquals(0, testGarden.CAMPX__Total_Unhealthy_Plant_Count__c, 'Expected default unhealthy plant count to be 0');
    }

    @isTest
    static void testInitializeDefaults_doesNotOverrideExistingValues() {
        CAMPX__Garden__c testGarden = new CAMPX__Garden__c(
            Name = 'Prepopulated Garden',
            CAMPX__Status__c = 'Operational',
            CAMPX__Max_Plant_Count__c = 200,
            CAMPX__Minimum_Plant_Count__c = 50,
            CAMPX__Total_Plant_Count__c = 100,
            CAMPX__Total_Unhealthy_Plant_Count__c = 3
        );
        List<CAMPX__Garden__c> gardenList = new List<CAMPX__Garden__c>{ testGarden };

        GardenDefaultsService.initializeDefaults(gardenList);

        System.assertEquals('Operational', testGarden.CAMPX__Status__c);
        System.assertEquals(200, testGarden.CAMPX__Max_Plant_Count__c);
        System.assertEquals(50, testGarden.CAMPX__Minimum_Plant_Count__c);
        System.assertEquals(100, testGarden.CAMPX__Total_Plant_Count__c);
        System.assertEquals(3, testGarden.CAMPX__Total_Unhealthy_Plant_Count__c);
    }

}
