public with sharing class GardenDefaultsService {
    public static void initializeDefaults(List<CAMPX__Garden__c> gardens) {
        for (CAMPX__Garden__c garden : gardens) {
            if (String.isBlank(garden.CAMPX__Status__c)) {
                garden.CAMPX__Status__c = 'Awaiting Resources';
            }
            if (garden.CAMPX__Max_Plant_Count__c == null) {
                garden.CAMPX__Max_Plant_Count__c = 100;
            }
            if (garden.CAMPX__Minimum_Plant_Count__c == null) {
                garden.CAMPX__Minimum_Plant_Count__c = 1;
            }
            if (garden.CAMPX__Total_Plant_Count__c == null) {
                garden.CAMPX__Total_Plant_Count__c = 0;
            }
            if (garden.CAMPX__Total_Unhealthy_Plant_Count__c == null) {
                garden.CAMPX__Total_Unhealthy_Plant_Count__c = 0;
            }
        }
    }
}
