@IsTest
private class RiskScoreRecalcBatchTest {

    @TestSetup
    static void setup() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 205; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Annual_Revenue__c = 100000 * (i + 1),
                Risk_Score__c = 10,
                Needs_Risk_Recalc__c = true
            ));
        }
        insert accounts;
    }

    @IsTest
    static void testBatchRecalculatesScores() {
        Test.startTest();
        Database.executeBatch(new RiskScoreRecalcBatch(), 200);
        Test.stopTest();

        List<Account> updated = [
            SELECT Id, Risk_Score__c, Needs_Risk_Recalc__c
            FROM Account
            WHERE Needs_Risk_Recalc__c = false
        ];
        System.assertEquals(205, updated.size(),
            'All accounts should be recalculated across both batch chunks');
    }

    @IsTest
    static void testHighRiskAccountsCreateHistory() {
        Account highRisk = new Account(
            Name = 'High Risk Co',
            Annual_Revenue__c = 50000000,
            Risk_Score__c = 10,
            Needs_Risk_Recalc__c = true
        );
        insert highRisk;

        Test.startTest();
        Database.executeBatch(new RiskScoreRecalcBatch(), 200);
        Test.stopTest();

        List<Account_Risk_History__c> history = [
            SELECT Id, Account__c, New_Score__c
            FROM Account_Risk_History__c
            WHERE Account__c = :highRisk.Id
        ];
        System.assert(!history.isEmpty(),
            'A risk history record should be created when score changes');
    }

    @IsTest
    static void testNoRecalcNeededSkipsUpdate() {
        Account stable = new Account(
            Name = 'Stable Co',
            Annual_Revenue__c = 200000,
            Risk_Score__c = 10,
            Needs_Risk_Recalc__c = false
        );
        insert stable;

        Test.startTest();
        Database.executeBatch(new RiskScoreRecalcBatch(), 200);
        Test.stopTest();

        Account result = [SELECT Risk_Score__c FROM Account WHERE Id = :stable.Id];
        System.assertEquals(10, result.Risk_Score__c,
            'Accounts not flagged for recalc should be untouched by the batch');
    }
}
