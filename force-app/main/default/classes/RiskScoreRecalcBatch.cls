/**
 * RiskScoreRecalcBatch
 *
 * Nightly batch job that recalculates risk scores for Accounts whose
 * related transaction or compliance data has changed since the last run.
 * Works alongside RiskScoringService (trigger-time scoring) to catch
 * accounts that need re-scoring outside of a direct field update —
 * e.g. after a bulk data load or a change to risk rules.
 *
 * Bulk-safe: avoids SOQL/DML inside loops, batches callouts-free logic
 * in chunks of 200, and writes results with a single bulk DML per batch.
 */
public class RiskScoreRecalcBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Integer accountsProcessed = 0;
    public Integer highRiskFlagged = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Annual_Revenue__c, Risk_Score__c,
                   (SELECT Id, Amount__c, Flagged__c FROM Transactions__r
                    WHERE CreatedDate = LAST_N_DAYS:30)
            FROM Account
            WHERE Needs_Risk_Recalc__c = true
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> toUpdate = new List<Account>();
        List<Account_Risk_History__c> historyRecords = new List<Account_Risk_History__c>();

        for (Account acc : scope) {
            Decimal newScore = RiskScoringService.calculateScore(acc, acc.Transactions__r);

            if (newScore != acc.Risk_Score__c) {
                Account updated = new Account(
                    Id = acc.Id,
                    Risk_Score__c = newScore,
                    Needs_Risk_Recalc__c = false
                );
                toUpdate.add(updated);

                historyRecords.add(new Account_Risk_History__c(
                    Account__c = acc.Id,
                    Previous_Score__c = acc.Risk_Score__c,
                    New_Score__c = newScore,
                    Reason__c = 'Batch recalculation'
                ));

                if (newScore >= RiskScoringService.HIGH_RISK_THRESHOLD) {
                    highRiskFlagged++;
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
        if (!historyRecords.isEmpty()) {
            Database.insert(historyRecords, false);
        }

        accountsProcessed += scope.size();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(
            'RiskScoreRecalcBatch complete. Accounts processed: ' + accountsProcessed +
            ', newly high-risk: ' + highRiskFlagged
        );
        // Compliance team notification is handled by ComplianceAlertFlow,
        // triggered off Account_Risk_History__c inserts above.
    }
}
