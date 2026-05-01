/**
 * AccountRiskScoringTrigger
 *
 * Fires on Account insert and update to calculate customer risk scores
 * for compliance review. Uses a service class pattern to keep business
 * logic separated from trigger context.
 *
 * Author: Urmila Boddapu
 * Last Modified: 2023-09-14
 */
trigger AccountRiskScoringTrigger on Account (before insert, before update) {

    List<Account> accountsToScore = new List<Account>();

    for (Account acc : Trigger.new) {
        if (Trigger.isInsert) {
            accountsToScore.add(acc);
        } else if (Trigger.isUpdate) {
            Account oldAcc = Trigger.oldMap.get(acc.Id);
            Boolean relevantFieldChanged = (
                acc.AnnualRevenue != oldAcc.AnnualRevenue ||
                acc.Industry != oldAcc.Industry ||
                acc.AccountSource != oldAcc.AccountSource ||
                acc.BillingCountry != oldAcc.BillingCountry
            );
            if (relevantFieldChanged) {
                accountsToScore.add(acc);
            }
        }
    }

    if (!accountsToScore.isEmpty()) {
        RiskScoringService.calculateRiskScores(accountsToScore);
    }
}
