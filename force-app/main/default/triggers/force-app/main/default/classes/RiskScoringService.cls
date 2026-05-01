/**
 * RiskScoringService
 *
 * Service class responsible for calculating customer risk scores.
 * Separated from trigger to allow independent testing and reuse.
 *
 * Score above 70  = High Risk
 * Score 40 to 70  = Medium Risk
 * Score below 40  = Low Risk
 *
 * Author: Urmila Boddapu
 * Last Modified: 2023-09-14
 */
public with sharing class RiskScoringService {

    private static final Set<String> HIGH_RISK_INDUSTRIES = new Set<String>{
        'Finance', 'Banking', 'Insurance', 'Cryptocurrency', 'Money Services'
    };

    private static final Set<String> MEDIUM_RISK_INDUSTRIES = new Set<String>{
        'Healthcare', 'Technology', 'Pharmaceuticals', 'Defense', 'Government'
    };

    private static final Set<String> HIGH_RISK_COUNTRIES = new Set<String>{
        'AF', 'IR', 'KP', 'MM', 'YE', 'SY'
    };

    public static void calculateRiskScores(List<Account> accounts) {

        for (Account acc : accounts) {
            Integer score = 0;

            if (acc.AnnualRevenue != null) {
                if (acc.AnnualRevenue > 10000000) {
                    score += 40;
                } else if (acc.AnnualRevenue > 1000000) {
                    score += 20;
                } else {
                    score += 5;
                }
            }

            if (String.isNotBlank(acc.Industry)) {
                if (HIGH_RISK_INDUSTRIES.contains(acc.Industry)) {
                    score += 30;
                } else if (MEDIUM_RISK_INDUSTRIES.contains(acc.Industry)) {
                    score += 15;
                } else {
                    score += 5;
                }
            }

            if (String.isNotBlank(acc.AccountSource)) {
                if (acc.AccountSource == 'Web' || acc.AccountSource == 'Cold Call') {
                    score += 20;
                } else if (acc.AccountSource == 'Partner' || acc.AccountSource == 'Purchased List') {
                    score += 10;
                } else {
                    score += 3;
                }
            } else {
                score += 20;
            }

            if (String.isNotBlank(acc.BillingCountry)) {
                String countryCode = acc.BillingCountry.toUpperCase();
                if (HIGH_RISK_COUNTRIES.contains(countryCode)) {
                    score += 10;
                }
            }

            acc.Risk_Score__c = score;

            if (score >= 70) {
                acc.Risk_Tier__c = 'High';
                acc.Compliance_Review_Required__c = true;
            } else if (score >= 40) {
                acc.Risk_Tier__c = 'Medium';
                acc.Compliance_Review_Required__c = false;
            } else {
                acc.Risk_Tier__c = 'Low';
                acc.Compliance_Review_Required__c = false;
            }
        }
    }
}
