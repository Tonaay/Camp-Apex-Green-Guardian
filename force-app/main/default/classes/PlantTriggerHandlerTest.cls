@isTest
private class PlantTriggerHandlerTest {

    @isTest
    static void testPlantTriggerHandler() {
        // Create a test Garden
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'Test Garden'
        );
        insert garden;

        // Create a test Plant
        CAMPX__Plant__c plant = new CAMPX__Plant__c(
            Name = 'Test Plant',
            CAMPX__Garden__c = garden.Id,
            CAMPX__Status__c = 'Healthy'
        );
        insert plant;

        // Update the test Plant
        plant.CAMPX__Status__c = 'Wilting';
        update plant;

        // Delete the test Plant
        delete plant;

        // Query the Garden to check if the counts are updated
        CAMPX__Garden__c updatedGarden = [SELECT Id, CAMPX__Total_Plant_Count__c, CAMPX__Total_Unhealthy_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden.Id];

        // Assert that the counts are updated correctly
        System.assertEquals(0, updatedGarden.CAMPX__Total_Plant_Count__c, 'Total plants count should be updated');
        System.assertEquals(0, updatedGarden.CAMPX__Total_Unhealthy_Plant_Count__c, 'Unhealthy plants count should be updated');
    }
}