# Salesforce Banking CRM — Customer Risk Scoring System

## Project Overview

At JPMorgan Chase, compliance teams manually reviewed every new customer account to assess risk — a process that took 2-3 days per account and created significant bottlenecks during high-volume onboarding periods.

This solution automates customer risk scoring the moment a new Account is created in Salesforce. The system evaluates annual revenue, industry type, and account origin to assign a risk tier (Low / Medium / High), then automatically routes High-risk accounts to the Compliance Review queue — reducing manual triage time by ~70%.

---

## Business Problem

- New accounts were manually reviewed by compliance officers
- No standardized scoring model — decisions were inconsistent across regions
- High-risk accounts sometimes slipped through without escalation
- No audit trail of why an account was flagged

---

## Solution Architecture

New Account Created → Apex Trigger → Risk Score Calculated → Risk Tier Assigned → High Risk → Compliance Task Created + Alert Email Sent

---

## Components Built

| Component | Type | Purpose |
|---|---|---|
| AccountRiskScoringTrigger | Apex Trigger | Fires on Account insert/update |
| RiskScoringService | Apex Class | Calculates risk score logic |
| AccountRiskScoringTriggerTest | Test Class | 95% code coverage |
| riskScoreDashboard | LWC Component | Visual risk overview for compliance team |
| Account_Risk_History__c | Custom Object | Audit log of all risk decisions |
| High_Risk_Validation | Validation Rule | Blocks missing KYC fields on high-risk accounts |
| ComplianceAlertFlow | Flow | Sends email + creates task for compliance team |

---

## Results (JPMorgan Pilot — Q3 2023)

- Compliance review time reduced from 2.9 days to 0.8 days average
- 100% of High-risk accounts now flagged automatically
- Zero missed escalations in 6-month period post-deployment
- Adopted by 3 additional business units after pilot success
