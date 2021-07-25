/*
 * Created by Stefan Serkin on July 23, 2021
 * */

 @isTest
private class AllocationTriggerHandler_Test {

    @TestSetup
    static void setupData(){

        Id hhRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household Account').getRecordTypeId();

        Account acc = new Account(Name='Tester Household', RecordTypeId=hhRecordTypeId);
        insert acc;

        Contact ct = new Contact(FirstName='Test', LastName='Tester', AccountId=acc.Id);
        insert ct;

        Opportunity opp = new Opportunity(Name='Test Gift', AccountId=acc.Id, CloseDate=Date.today().addDays(1), StageName='Prospecting', Amount=100);
        insert opp;

        npsp__General_Accounting_Unit__c oldGau = new npsp__General_Accounting_Unit__c(Name='Old GAU', npsp__Active__c=true);
        insert oldGau;

        npsp__General_Accounting_Unit__c newGau = new npsp__General_Accounting_Unit__c(Name='New GAU', npsp__Active__c=true);
        insert newGau;

        npsp__General_Accounting_Unit__c otherGau = new npsp__General_Accounting_Unit__c(Name='Other GAU', npsp__Active__c=true);
        insert otherGau;

        npsp__Allocation__c alloc = new npsp__Allocation__c(npsp__Amount__c=50, npsp__General_Accounting_Unit__c=oldGau.Id, npsp__Opportunity__c=opp.Id, npsp__Percent__c=50);
        insert alloc;

    }
    
    @isTest
    static void testRollupAllocNames() {

        Opportunity opp = [SELECT Id, GAU_Allocations__c FROM Opportunity WHERE Name = 'Test Gift' LIMIT 1];

        Map<String, npsp__General_Accounting_Unit__c> mapNamesToGaus = new Map<String, npsp__General_Accounting_Unit__c>();
        List<npsp__General_Accounting_Unit__c> lstGaus = [SELECT Name, Id FROM npsp__General_Accounting_Unit__c LIMIT 3];
        for (npsp__General_Accounting_Unit__c gau : lstGaus) {
            mapNamesToGaus.put(gau.Name, gau);
        }

        npsp__General_Accounting_Unit__c oldGau   = mapNamesToGaus.get('Old GAU');
        npsp__General_Accounting_Unit__c newGau   = mapNamesToGaus.get('New GAU');
        npsp__General_Accounting_Unit__c otherGau = mapNamesToGaus.get('Other GAU');

        Test.startTest();
        npsp__Allocation__c newAlloc   = new npsp__Allocation__c(npsp__Amount__c=25, npsp__General_Accounting_Unit__c=newGau.Id, npsp__Opportunity__c=opp.Id, npsp__Percent__c=25);
        insert newAlloc;
        npsp__Allocation__c otherAlloc = new npsp__Allocation__c(npsp__Amount__c=25, npsp__General_Accounting_Unit__c=otherGau.Id, npsp__Opportunity__c=opp.Id, npsp__Percent__c=25);
        insert otherAlloc;
        Test.stopTest();

        Opportunity oppToVerify = [SELECT Id, GAU_Allocations__c FROM Opportunity WHERE Name = 'Test Gift' LIMIT 1];

        String expectedGauString = newGau.Name + ', ' + oldGau.Name + ' and ' + otherGau.Name;

        System.assertEquals(expectedGauString, 
            oppToVerify.GAU_Allocations__c, 
            'GAU names unexpected');

    }

    @isTest
    static void testDuplicateAllocNames() {

        Opportunity opp = [SELECT Id, GAU_Allocations__c FROM Opportunity WHERE Name = 'Test Gift' LIMIT 1];

        Map<String, npsp__General_Accounting_Unit__c> mapNamesToGaus = new Map<String, npsp__General_Accounting_Unit__c>();
        List<npsp__General_Accounting_Unit__c> lstGaus = [SELECT Name, Id FROM npsp__General_Accounting_Unit__c LIMIT 2];
        for (npsp__General_Accounting_Unit__c gau : lstGaus) {
            mapNamesToGaus.put(gau.Name, gau);
        }

        npsp__General_Accounting_Unit__c oldGau = mapNamesToGaus.get('Old GAU');
        npsp__General_Accounting_Unit__c newGau = mapNamesToGaus.get('New GAU');

        Test.startTest();
        npsp__Allocation__c newAlloc = new npsp__Allocation__c(npsp__Amount__c=50, npsp__General_Accounting_Unit__c=oldGau.Id, npsp__Opportunity__c=opp.Id, npsp__Percent__c=50);
        insert newAlloc;
        Test.stopTest();

        Opportunity oppToVerify = [SELECT Id, GAU_Allocations__c FROM Opportunity WHERE Name = 'Test Gift' LIMIT 1];

        String expectedGauString = oldGau.Name;

        System.assertEquals(expectedGauString, 
            oppToVerify.GAU_Allocations__c, 
            'GAU names unexpected');

    }

    @isTest
    static void testDeleteAllocNames() {

        Opportunity opp = [SELECT Id, GAU_Allocations__c, (SELECT Id FROM npsp__Allocations__r) FROM Opportunity WHERE Name = 'Test Gift' LIMIT 1];

        Map<String, npsp__General_Accounting_Unit__c> mapNamesToGaus = new Map<String, npsp__General_Accounting_Unit__c>();
        List<npsp__General_Accounting_Unit__c> lstGaus = [SELECT Name, Id FROM npsp__General_Accounting_Unit__c LIMIT 2];
        for (npsp__General_Accounting_Unit__c gau : lstGaus) {
            mapNamesToGaus.put(gau.Name, gau);
        }

        npsp__General_Accounting_Unit__c oldGau = mapNamesToGaus.get('Old GAU');
        npsp__General_Accounting_Unit__c newGau = mapNamesToGaus.get('New GAU');

        // Insert allocation with newGau before testing removal of oldGau
        npsp__Allocation__c newAlloc = new npsp__Allocation__c(npsp__Amount__c=50, npsp__General_Accounting_Unit__c=newGau.Id, npsp__Opportunity__c=opp.Id, npsp__Percent__c=50);
        insert newAlloc;

        npsp__Allocation__c oldAlloc = opp.npsp__Allocations__r.get(0);

        Test.startTest();
        Database.DeleteResult dr = Database.delete(oldAlloc);
        Test.stopTest();

        Opportunity oppToVerify = [SELECT Id, GAU_Allocations__c FROM Opportunity WHERE Name = 'Test Gift' LIMIT 1];

        String expectedGauString = newGau.Name;

        System.assert(dr.isSuccess(), 'Deletion unsuccessful');

        System.assertEquals(expectedGauString, 
            oppToVerify.GAU_Allocations__c, 
            'GAU Allocations value unexpected');

    }
    
}