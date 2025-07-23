public with sharing class PlantGardenService {
    public static void syncPlantCounts(List<CAMPX__Plant__c> plants, List<CAMPX__Plant__c> oldList) {
        Set<Id> affectedGardenIds = new Set<Id>();

        // Safely process plants (for insert/update)
        if (plants != null) {
            for (CAMPX__Plant__c plant : plants) {
                if (plant.CAMPX__Garden__c != null) {
                    affectedGardenIds.add(plant.CAMPX__Garden__c);
                }
            }
        }

        // Safely process oldList (for update/delete)
        if (oldList != null) {
            for (CAMPX__Plant__c plant : oldList) {
                if (plant.CAMPX__Garden__c != null) {
                    affectedGardenIds.add(plant.CAMPX__Garden__c);
                }
            }
        }

        if (!affectedGardenIds.isEmpty()) {
            Map<Id, Integer> gardenToPlantCount = new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT CAMPX__Garden__c gardenId, COUNT(Id) plantCount
                FROM CAMPX__Plant__c
                WHERE CAMPX__Garden__c IN :affectedGardenIds
                GROUP BY CAMPX__Garden__c
            ]) {
                gardenToPlantCount.put((Id)result.get('gardenId'), (Integer)result.get('plantCount'));
            }

            List<CAMPX__Garden__c> gardensToUpdate = new List<CAMPX__Garden__c>();
            for (Id gardenId : affectedGardenIds) {
                gardensToUpdate.add(new CAMPX__Garden__c(
                    Id = gardenId,
                    CAMPX__Total_Plant_Count__c = gardenToPlantCount.get(gardenId) != null
                        ? gardenToPlantCount.get(gardenId)
                        : 0
                ));
            }

            if (!gardensToUpdate.isEmpty()) {
                update gardensToUpdate;
            }
        }
    }

    public static void syncUnhealthyPlantCount(List<CAMPX__Plant__c> plants, List<CAMPX__Plant__c> oldList){
        Set<String> unhealthyStatuses = new Set<String>{'Sick', 'Deceased', 'Wilting'};
        Set<Id> affectedGardenIds = new Set<Id>();
        Map<Id, Integer> unhealthyPlantCount = new Map<Id, Integer>();
        
        // Build oldMap for quick lookup by Id
        Map<Id, CAMPX__Plant__c> oldMap = new Map<Id, CAMPX__Plant__c>();
        if (oldList != null) {
            for (CAMPX__Plant__c oldPlant : oldList) {
                oldMap.put(oldPlant.Id, oldPlant);
            }
        }
        
        if (plants != null) {
            for (CAMPX__Plant__c plant : plants) {
                CAMPX__Plant__c oldPlant = oldMap.get(plant.Id);
                
                Boolean wasUnhealthy = oldPlant != null && unhealthyStatuses.contains(oldPlant.CAMPX__Status__c);
                Boolean isUnhealthy = plant.CAMPX__Status__c != null && unhealthyStatuses.contains(plant.CAMPX__Status__c);
                
                if (wasUnhealthy != isUnhealthy) {
                    affectedGardenIds.add(plant.CAMPX__Garden__c);
                }
            }
        }

        if (oldList != null) {
            for (CAMPX__Plant__c oldPlant : oldList) {
                if (oldPlant.CAMPX__Garden__c != null) {
                    affectedGardenIds.add(oldPlant.CAMPX__Garden__c);
                }
            }
        }

        if (!affectedGardenIds.isEmpty()) {
            for (AggregateResult result : [
                SELECT CAMPX__Garden__c gardenId, COUNT(Id) unhealthyCount
                FROM CAMPX__Plant__c
                WHERE CAMPX__Status__c IN :unhealthyStatuses
                AND CAMPX__Garden__c IN :affectedGardenIds
                GROUP BY CAMPX__Garden__c
            ]) {
                unhealthyPlantCount.put((Id)result.get('gardenId'), (Integer)result.get('unhealthyCount'));
            }

            List<CAMPX__Garden__c> gardensToUpdate = new List<CAMPX__Garden__c>();
            for (Id gardenId : affectedGardenIds) {
                gardensToUpdate.add(new CAMPX__Garden__c(
                    Id = gardenId,
                    CAMPX__Total_Unhealthy_Plant_Count__c = unhealthyPlantCount.containsKey(gardenId) 
                        ? unhealthyPlantCount.get(gardenId) 
                        : 0
                ));
            }

            if (!gardensToUpdate.isEmpty()) {
                update gardensToUpdate;
            }
        }
    }

    public static void validatePlantsWithClosedGardens(List<CAMPX__Plant__c> plants, Map<Id, CAMPX__Plant__c> oldMap) {
        Set<Id> gardensToQuery = new Set<Id>();
        Map<Id, List<CAMPX__Plant__c>> gardenToPlantsMap = new Map<Id, List<CAMPX__Plant__c>>();

        for (CAMPX__Plant__c plant : plants) {
            Boolean isNew = oldMap == null || !oldMap.containsKey(plant.Id);
            Boolean isGardenChanged = isNew || plant.CAMPX__Garden__c != oldMap.get(plant.Id).CAMPX__Garden__c;

            if (plant.CAMPX__Garden__c != null && isGardenChanged) {
                gardensToQuery.add(plant.CAMPX__Garden__c);

                if (!gardenToPlantsMap.containsKey(plant.CAMPX__Garden__c)) {
                    gardenToPlantsMap.put(plant.CAMPX__Garden__c, new List<CAMPX__Plant__c>());
                }
                gardenToPlantsMap.get(plant.CAMPX__Garden__c).add(plant);
            }
        }

        if (!gardensToQuery.isEmpty()) {
            List<CAMPX__Garden__c> closedGardens = [
                SELECT Id
                FROM CAMPX__Garden__c
                WHERE Id IN :gardensToQuery AND CAMPX__Status__c = 'Permanent Closure'
            ];

            Set<Id> closedGardenIds = new Set<Id>();
            for (CAMPX__Garden__c closedGarden : closedGardens) {
                closedGardenIds.add(closedGarden.Id);
            }

            for (Id gardenId : closedGardenIds) {
                List<CAMPX__Plant__c> plantsToFlag = gardenToPlantsMap.get(gardenId);
                if (plantsToFlag != null) {
                    for (CAMPX__Plant__c plant : plantsToFlag) {
                        plant.addError('The garden selected for this plant is permanently closed. Please select a different garden.');
                    }
                }
            }
        }
    }

}