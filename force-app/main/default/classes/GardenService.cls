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

}
