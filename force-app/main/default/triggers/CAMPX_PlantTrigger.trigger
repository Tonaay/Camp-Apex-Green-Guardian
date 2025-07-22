trigger CAMPX_PlantTrigger on CAMPX__Plant__c (before insert, after insert, after update, after delete) {
    PlantTriggerHandler.handle(trigger.new, trigger.oldMap);
}
