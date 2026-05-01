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
