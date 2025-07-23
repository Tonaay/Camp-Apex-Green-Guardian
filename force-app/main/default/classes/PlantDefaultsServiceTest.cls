@isTest
private class PlantDefaultsServiceTest {

    @isTest
    static void testInitializeDefaults_withGardenSunExposure() {
        // Create a garden with Sun Exposure set
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'Sunny Garden',
            CAMPX__Sun_Exposure__c = 'Full Sun'
        );
        insert garden;

        // Create a plant with no defaults filled in, linked to the garden
        CAMPX__Plant__c plant = new CAMPX__Plant__c(
            Name = 'Tomato',
            CAMPX__Garden__c = garden.Id
        );

        Test.startTest();
            PlantDefaultsService.initializeDefaults(new List<CAMPX__Plant__c>{plant});
        Test.stopTest();

        // Assert that defaults are set correctly
        System.assertEquals('All Purpose Potting Soil', plant.CAMPX__Soil_Type__c, 'Default soil type not set');
        System.assertEquals('Once Weekly', plant.CAMPX__Water__c, 'Default watering schedule not set');
        System.assertEquals('Full Sun', plant.CAMPX__Sunlight__c, 'Sunlight should match garden exposure');
    }

    @isTest
    static void testInitializeDefaults_withoutGardenReference() {
        // Create a plant with no garden and no default fields
        CAMPX__Plant__c plant = new CAMPX__Plant__c(Name = 'Lettuce');

        Test.startTest();
            PlantDefaultsService.initializeDefaults(new List<CAMPX__Plant__c>{plant});
        Test.stopTest();

        System.assertEquals('All Purpose Potting Soil', plant.CAMPX__Soil_Type__c, 'Soil should default');
        System.assertEquals('Once Weekly', plant.CAMPX__Water__c, 'Watering should default');
        System.assertEquals('Partial Sun', plant.CAMPX__Sunlight__c, 'Sunlight should fall back to Partial Sun');
    }

    @isTest
    static void testInitializeDefaults_gardenWithNoSunExposure() {
        // Garden has no Sun Exposure set
        CAMPX__Garden__c garden = new CAMPX__Garden__c(Name = 'Shady Garden');
        insert garden;

        CAMPX__Plant__c plant = new CAMPX__Plant__c(
            Name = 'Fern',
            CAMPX__Garden__c = garden.Id
        );

        Test.startTest();
            PlantDefaultsService.initializeDefaults(new List<CAMPX__Plant__c>{plant});
        Test.stopTest();

        System.assertEquals('Partial Sun', plant.CAMPX__Sunlight__c, 'Should fall back to Partial Sun if garden exposure is blank');
    }

    @isTest
    static void testInitializeDefaults_doesNotOverrideSetFields() {
        // Garden with exposure
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            Name = 'Custom Garden',
            CAMPX__Sun_Exposure__c = 'Partial Shade'
        );
        insert garden;

        // Plant already has fields populated
        CAMPX__Plant__c plant = new CAMPX__Plant__c(
            Name = 'Basil',
            CAMPX__Garden__c = garden.Id,
            CAMPX__Soil_Type__c = 'Herb Mix',
            CAMPX__Water__c = 'Twice Weekly',
            CAMPX__Sunlight__c = 'Indirect Sun'
        );

        Test.startTest();
            PlantDefaultsService.initializeDefaults(new List<CAMPX__Plant__c>{plant});
        Test.stopTest();

        // None of these should be overwritten
        System.assertEquals('Herb Mix', plant.CAMPX__Soil_Type__c, 'Soil type should not be overridden');
        System.assertEquals('Twice Weekly', plant.CAMPX__Water__c, 'Watering schedule should not be overridden');
        System.assertEquals('Indirect Sun', plant.CAMPX__Sunlight__c, 'Sunlight should not be overridden');
    }
}
