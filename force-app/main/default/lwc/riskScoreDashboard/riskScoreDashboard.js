import { LightningElement, wire, track } from 'lwc';
import getHighRiskAccounts from '@salesforce/apex/RiskDashboardController.getHighRiskAccounts';
import getRiskSummary from '@salesforce/apex/RiskDashboardController.getRiskSummary';

const COLUMNS = [
    { label: 'Account Name', fieldName: 'accountUrl', type: 'url',
      typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
    { label: 'Industry', fieldName: 'Industry', type: 'text' },
    { label: 'Annual Revenue', fieldName: 'AnnualRevenue', type: 'currency' },
    { label: 'Risk Score', fieldName: 'Risk_Score__c', type: 'number' },
    { label: 'Country', fieldName: 'BillingCountry', type: 'text' },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
];

export default class RiskScoreDashboard extends LightningElement {

    @track highRiskAccounts = [];
    @track highRiskCount = 0;
    @track mediumRiskCount = 0;
    @track lowRiskCount = 0;
    @track isLoading = true;

    columns = COLUMNS;
    sortedBy = 'Risk_Score__c';
    sortedDirection = 'desc';

    @wire(getHighRiskAccounts)
    wiredHighRisk({ data, error }) {
        if (data) {
            this.highRiskAccounts = data.map(acc => ({
                ...acc,
                accountUrl: `/lightning/r/Account/${acc.Id}/view`
            }));
            this.isLoading = false;
        } else if (error) {
            console.error('Error loading high risk accounts:', error);
            this.isLoading = false;
        }
    }

    @wire(getRiskSummary)
    wiredSummary({ data, error }) {
        if (data) {
            this.highRiskCount = data.highCount || 0;
            this.mediumRiskCount = data.mediumCount || 0;
            this.lowRiskCount = data.lowCount || 0;
        } else if (error) {
            console.error('Error loading risk summary:', error);
        }
    }

    get hasHighRiskAccounts() {
        return this.highRiskAccounts && this.highRiskAccounts.length > 0;
    }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy, this.sortedDirection);
    }

    sortData(field, direction) {
        const cloneData = [...this.highRiskAccounts];
        cloneData.sort((a, b) => {
            let valA = a[field] || '';
            let valB = b[field] || '';
            return direction === 'asc'
                ? valA > valB ? 1 : -1
                : valA < valB ? 1 : -1;
        });
        this.highRiskAccounts = cloneData;
    }
}
