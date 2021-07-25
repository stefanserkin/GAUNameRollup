/*
 * Created by Stefan Serkin on July 23, 2021
 * */

public without sharing class AllocationTriggerHandler {

    public static void rollupAllocNames(List<npsp__Allocation__c> lstAllocsInTrigger) {

        Map<Id, Opportunity> mapOppysToUpdate = new Map<Id, Opportunity>();

        Set<Id> setOppIds = new Set<Id>();
        for (npsp__Allocation__c alloc : lstAllocsInTrigger) {
            setOppIds.add(alloc.npsp__Opportunity__c);
        }

        List<Opportunity> lstOppys = [SELECT Id, 
                                             Name, 
                                             GAU_Allocations__c, 
                                             (SELECT Id, 
                                                     npsp__General_Accounting_Unit__r.Name 
                                                FROM npsp__Allocations__r)
                                        FROM Opportunity
                                       WHERE Id IN :setOppIds
                                        WITH SECURITY_ENFORCED];

        if (!lstOppys.isEmpty()) {
            mapOppysToUpdate = getOppysToUpdate(lstOppys);
        }

        if (!mapOppysToUpdate.isEmpty()) {
            try {
                update mapOppysToUpdate.values();
            } catch (DmlException e) {
                System.debug('An error occured: ' + e.getMessage());
            }
        }

    }


    private static Map<Id, Opportunity> getOppysToUpdate(List<Opportunity> lstOppys) {

        Map<Id, Opportunity> mapResults = new Map<Id, Opportunity>();

        for (Opportunity oppy : lstOppys) {
            // Final string to be assigned to oppy
            String strFinalGauNames   = '';

            Set<String> setUniqueNames  = new Set<String>();
            List<String> lstUniqueNames = new List<String>();
            
            for (npsp__Allocation__c oppyAlloc : oppy.npsp__Allocations__r) {
                // If no gau name, move along
                if (oppyAlloc.npsp__General_Accounting_Unit__r.Name == null) {
                    continue;
                }
                // Add to set to de-duplicate
                setUniqueNames.add(oppyAlloc.npsp__General_Accounting_Unit__r.Name);
            }
            // Put in list to sort alphabetically
            lstUniqueNames.addAll(setUniqueNames);
            lstUniqueNames.sort();
            // Return formatted final string
            strFinalGauNames = concatenateDistinctNameFromList(lstUniqueNames);

            if (oppy.GAU_Allocations__c != strFinalGauNames) {
                oppy.GAU_Allocations__c = strFinalGauNames;
                mapResults.put(oppy.Id, oppy);
            }
        }
        
        return mapResults;

    }

    private static String concatenateDistinctNameFromList(List<String> lstNames) {
        String result        = '';
        Integer intNameCount = 0;
        Boolean isFirstAlloc = true;

        for (String name : lstNames) {
            intNameCount++;
            // Add punctuation if not the first name in the list
            if (!isFirstAlloc) {
                if (intNameCount < lstNames.size()) {
                    result += ', ';
                } else {
                    result += ' and ';
                }
            }
            // For each alphabatized unique name, add to final string
            result += name;

            if (isFirstAlloc) {
                isFirstAlloc = false;
            }
            
        }

        return result;

    }
    
}
