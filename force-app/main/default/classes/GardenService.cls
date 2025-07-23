public with sharing class GardenService {

    public static void changeManagerStartDate(List<CAMPX__Garden__c> gardens, Map<Id, CAMPX__Garden__c> oldMap) {
        for (CAMPX__Garden__c garden : gardens) {
            CAMPX__Garden__c oldGarden = (oldMap != null) ? oldMap.get(garden.Id) : null;

            if (oldGarden != null) {
                if (garden.CAMPX__Manager__c != oldGarden.CAMPX__Manager__c && garden.CAMPX__Manager__c != null) {
                    garden.CAMPX__Manager_Start_Date__c = System.today();
                } else if (garden.CAMPX__Manager__c == null && oldGarden.CAMPX__Manager__c != null) {
                    garden.CAMPX__Manager_Start_Date__c = null;
                }
            } else {
                if (garden.CAMPX__Manager__c != null) {
                    garden.CAMPX__Manager_Start_Date__c = System.today();
                }
            }
        }
    }

    public static void calculateCapacity(List<CAMPX__Garden__c> gardens, Map<Id, CAMPX__Garden__c> oldMap) {
        for (CAMPX__Garden__c garden : gardens) {
            Boolean shouldCalculate = true;

            if (garden.CAMPX__Total_Plant_Count__c == null || garden.CAMPX__Max_Plant_Count__c == null || 
                garden.CAMPX__Max_Plant_Count__c == 0) {
                garden.CAMPX__Capacity__c = 0; 
            continue;
            }

            if (oldMap != null) {
                CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
                if (oldGarden != null &&
                    garden.CAMPX__Total_Plant_Count__c == oldGarden.CAMPX__Total_Plant_Count__c &&
                    garden.CAMPX__Max_Plant_Count__c == oldGarden.CAMPX__Max_Plant_Count__c) {
                    shouldCalculate = false;
                }
            }

            if (shouldCalculate) {
                garden.CAMPX__Capacity__c =
                    (garden.CAMPX__Total_Plant_Count__c / garden.CAMPX__Max_Plant_Count__c) * 100;
            }
        }
    }

    public static void calculateHealthIndex(List<CAMPX__Garden__c> gardens, Map<Id, CAMPX__Garden__c> oldMap) {
        for (CAMPX__Garden__c garden : gardens) {
            Decimal totalPlantCount = garden.CAMPX__Total_Plant_Count__c == null ? 0 : garden.CAMPX__Total_Plant_Count__c;
            Decimal totalUnhealthyCount = garden.CAMPX__Total_Unhealthy_Plant_Count__c == null ? 0 : garden.CAMPX__Total_Unhealthy_Plant_Count__c;

            Boolean shouldRecalculate = true;

            // Only check oldMap in before update context
            if (oldMap != null && oldMap.containsKey(garden.Id)) {
                CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
                shouldRecalculate = 
                    garden.CAMPX__Total_Plant_Count__c != oldGarden.CAMPX__Total_Plant_Count__c ||
                    garden.CAMPX__Total_Unhealthy_Plant_Count__c != oldGarden.CAMPX__Total_Unhealthy_Plant_Count__c;
            }

            if (shouldRecalculate) {
                if (totalPlantCount == 0) {
                    garden.CAMPX__Health_Index__c = 0;
                } else {
                    garden.CAMPX__Health_Index__c = 
                        ((totalPlantCount - totalUnhealthyCount) / totalPlantCount) * 100;
                }
            }
        }
    }

    public static void setGardenStatus(List<CAMPX__Garden__c> gardens, Map<Id, CAMPX__Garden__c> oldMap) {

        for (CAMPX__Garden__c garden : gardens) {

            Boolean shouldRecalculateStatus = true;

            // If the garden was previously marked as Permanent Closure, preserve it
            if (oldMap != null && oldMap.containsKey(garden.Id)) {
                CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
                if (oldGarden.CAMPX__Status__c == 'Permanent Closure') {
                    garden.CAMPX__Status__c = 'Permanent Closure';
                    continue; // skip further recalculation
                }

                shouldRecalculateStatus =
                    garden.CAMPX__Total_Plant_Count__c != oldGarden.CAMPX__Total_Plant_Count__c ||
                    garden.CAMPX__Minimum_Plant_Count__c != oldGarden.CAMPX__Minimum_Plant_Count__c ||
                    garden.CAMPX__Health_Index__c != oldGarden.CAMPX__Health_Index__c ||
                    garden.CAMPX__Capacity__c != oldGarden.CAMPX__Capacity__c;
            }

            if (shouldRecalculateStatus) {

                // Null-safe field defaults
                Decimal capacity = garden.CAMPX__Capacity__c == null ? 0 : garden.CAMPX__Capacity__c;
                Decimal healthIndex = garden.CAMPX__Health_Index__c == null ? 0 : garden.CAMPX__Health_Index__c;
                Decimal minPlantCount = garden.CAMPX__Minimum_Plant_Count__c == null ? 0 : garden.CAMPX__Minimum_Plant_Count__c;
                Decimal totalPlantCount = garden.CAMPX__Total_Plant_Count__c == null ? 0 : garden.CAMPX__Total_Plant_Count__c;

                if (capacity >= 70 && capacity <= 100 && healthIndex >= 70) {
                    garden.CAMPX__Status__c = 'Operational';
                }
                else if (capacity == 0) {
                    garden.CAMPX__Status__c = 'Temporary Closure';
                }
                else if (capacity >= 100) {
                    garden.CAMPX__Status__c = 'Over Capacity';
                }
                else if (capacity < 70 || healthIndex < 70 || minPlantCount > totalPlantCount) {
                    garden.CAMPX__Status__c = 'Awaiting Resources';
                }
            }
        }
    }

}
