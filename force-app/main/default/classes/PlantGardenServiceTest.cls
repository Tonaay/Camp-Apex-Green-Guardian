@isTest
private class PlantGardenServiceTest {

    static testMethod void testSyncPlantCounts_Delete() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(Name = 'Sync Garden');
        insert garden;

        CAMPX__Plant__c plant = new CAMPX__Plant__c(Name = 'Rose', CAMPX__Garden__c = garden.Id);
        insert plant;

        Test.startTest();
            delete plant;
            PlantGardenService.syncPlantCounts(null, new List<CAMPX__Plant__c>{ plant });
        Test.stopTest();

        garden = [SELECT CAMPX__Total_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden.Id];
        System.assertEquals(0, garden.CAMPX__Total_Plant_Count__c, 'Plant count should be updated after deletion.');
    }

    static testMethod void testSyncUnhealthyPlantCount_Update() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(Name = 'Sync Garden');
        insert garden;

        CAMPX__Plant__c plant1 = new CAMPX__Plant__c(Name = 'Rose', CAMPX__Garden__c = garden.Id, CAMPX__Status__c = 'Healthy');
        CAMPX__Plant__c plant2 = new CAMPX__Plant__c(Name = 'Tulip', CAMPX__Garden__c = garden.Id, CAMPX__Status__c = 'Sick');
        insert new List<CAMPX__Plant__c>{ plant1, plant2 };

        plant1.CAMPX__Status__c = 'Wilting';
        plant2.CAMPX__Status__c = 'Healthy';

        Test.startTest();
            PlantGardenService.syncUnhealthyPlantCount(new List<CAMPX__Plant__c>{ plant1, plant2 }, new List<CAMPX__Plant__c>{ plant1, plant2 });
        Test.stopTest();

        garden = [SELECT CAMPX__Total_Unhealthy_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden.Id];
        System.assertEquals(1, garden.CAMPX__Total_Unhealthy_Plant_Count__c, 'Should count one unhealthy plant.');
    }

    static testMethod void testValidatePlantsWithClosedGardens() {
        // Create and insert the Garden
        CAMPX__Garden__c closedGarden = new CAMPX__Garden__c(Name = 'Closed Garden');
        insert closedGarden;

        // Re-query and explicitly set status to 'Permanent Closure' in case it was overridden
        closedGarden = [SELECT Id, CAMPX__Status__c FROM CAMPX__Garden__c WHERE Id = :closedGarden.Id];
        closedGarden.CAMPX__Status__c = 'Permanent Closure';
        update closedGarden;

        // Create a Plant referencing the closed garden
        CAMPX__Plant__c plant = new CAMPX__Plant__c(Name = 'Daisy', CAMPX__Garden__c = closedGarden.Id);

        Test.startTest();
        Database.SaveResult result = Database.insert(plant, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess(), 'Insert should fail due to closed garden.');
        System.assertEquals(1, result.getErrors().size(), 'Should have exactly one error.');
        System.assertEquals(
            'The garden selected for this plant is permanently closed. Please select a different garden.',
            result.getErrors()[0].getMessage(),
            'Should not allow plants to be added to closed gardens.'
        );
    }

}