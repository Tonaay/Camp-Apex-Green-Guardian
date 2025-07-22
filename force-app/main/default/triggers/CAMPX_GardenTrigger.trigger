trigger CAMPX_GardenTrigger on CAMPX__Garden__c (
    before insert, before update,
    after insert, after update
) {
    GardenTriggerHandler.handle(trigger.new, trigger.oldMap);
}
