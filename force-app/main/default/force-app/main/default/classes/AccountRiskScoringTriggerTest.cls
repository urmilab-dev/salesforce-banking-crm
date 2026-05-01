@isTest
private class AccountRiskScoringTriggerTest {

    @isTest
    static void testHighRiskAccount() {
        Account acc = new Account(
            Name = 'Crypto Exchange Corp',
            AnnualRevenue = 50000000,
            Industry = 'Cryptocurrency',
            AccountSource = 'Web',
            BillingCountry = 'US'
        );
        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT Risk_Score__c, Risk_Tier__c, Compliance_Review_Required__c
                          FROM Account WHERE Id = :acc.Id];
        System.assertEquals('High', result.Risk_Tier__c, 'Expected High risk tier');
        System.assert(result.Risk_Score__c >= 70, 'Score should be 70 or above');
        System.assert(result.Compliance_Review_Required__c, 'Compliance review flag should be true');
    }

    @isTest
    static void testLowRiskAccount() {
        Account acc = new Account(
            Name = 'Local Bakery Ltd',
            AnnualRevenue = 200000,
            Industry = 'Retail',
            AccountSource = 'Employee Referral',
            BillingCountry = 'US'
        );
        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT Risk_Score__c, Risk_Tier__c, Compliance_Review_Required__c
                          FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Low', result.Risk_Tier__c, 'Expected Low risk tier');
        System.assert(result.Risk_Score__c < 40, 'Score should be below 40');
        System.assertEquals(false, result.Compliance_Review_Required__c, 'No compliance review needed');
    }

    @isTest
    static void testRescoreOnCountryUpdate() {
        Account acc = new Account(
            Name = 'International Holdings',
            AnnualRevenue = 5000000,
            Industry = 'Finance',
            AccountSource = 'Partner',
            BillingCountry = 'US'
        );
        insert acc;
        Test.startTest();
        acc.BillingCountry = 'IR';
        update acc;
        Test.stopTest();

        Account result = [SELECT Risk_Score__c, Risk_Tier__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('High', result.Risk_Tier__c, 'Country change should escalate to High');
    }

    @isTest
    static void testBulkInsert() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Test Account ' + i,
                AnnualRevenue = 500000 * i,
                Industry = 'Technology',
                AccountSource = 'Web',
                BillingCountry = 'US'
            ));
        }
        Test.startTest();
        insert accounts;
        Test.stopTest();

        List<Account> results = [SELECT Risk_Tier__c FROM Account WHERE Name LIKE 'Bulk Test Account%'];
        System.assertEquals(200, results.size(), 'All 200 accounts should be inserted and scored');
    }

    @isTest
    static void testNullFieldsSafeHandling() {
        Account acc = new Account(
            Name = 'Minimal Data Corp',
            BillingCountry = 'US'
        );
        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT Risk_Tier__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, result.Risk_Tier__c, 'Risk tier should always be assigned');
    }
}
