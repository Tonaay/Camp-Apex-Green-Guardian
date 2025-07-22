public with sharing class PlantDefaultsService {
    public static void initializeDefaults(List<CAMPX__Plant__c> plants) {
    Set<Id> gardenIds = new Set<Id>();

        for (CAMPX__Plant__c plant : plants) {
            if (plant.CAMPX__Garden__c != null) {
                gardenIds.add(plant.CAMPX__Garden__c);
            }
        }

        Map<Id, CAMPX__Garden__c> gardenMap = new Map<Id, CAMPX__Garden__c>();
        if (!gardenIds.isEmpty()) {
            gardenMap = new Map<Id, CAMPX__Garden__c>(
                [SELECT Id, CAMPX__Sun_Exposure__c FROM CAMPX__Garden__c WHERE Id IN :gardenIds]
            );
        }

        for (CAMPX__Plant__c plant : plants) {
            if (String.isBlank(plant.CAMPX__Soil_Type__c)) {
                plant.CAMPX__Soil_Type__c = 'All Purpose Potting Soil';
            }

            if (String.isBlank(plant.CAMPX__Water__c)) {
                plant.CAMPX__Water__c = 'Once Weekly';
            }

            if (String.isBlank(plant.CAMPX__Sunlight__c)) {
                if (
                    plant.CAMPX__Garden__c != null &&
                    gardenMap.containsKey(plant.CAMPX__Garden__c) &&
                    !String.isBlank(gardenMap.get(plant.CAMPX__Garden__c).CAMPX__Sun_Exposure__c)
                ) {
                    plant.CAMPX__Sunlight__c = gardenMap.get(plant.CAMPX__Garden__c).CAMPX__Sun_Exposure__c;
                } else {
                    plant.CAMPX__Sunlight__c = 'Partial Sun';
                }
            }
        }
    }
}