/*
 * Created by Stefan Serkin on July 23, 2021
 * */

trigger AllocationTrigger on npsp__Allocation__c (after insert, after update, after delete, after undelete) {

    if (Trigger.isDelete) {
        AllocationTriggerHandler.rollupAllocNames(Trigger.old);
    } else {
        AllocationTriggerHandler.rollupAllocNames(Trigger.new);
    }
    
}