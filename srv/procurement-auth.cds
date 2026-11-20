using ProcurementService from './procurementService';

annotate ProcurementService.PurchaseRequisitions with @restrict: [
    {
        grant: 'READ',
        to: ['Requester', 'DepartmentManager', 'ITHead', 'FinanceApprover', 'CFO', 'ProcurementOfficer', 'Administrator', 'system-user']
    },
    {
        grant: ['CREATE', 'UPDATE'],
        to: ['Requester', 'Administrator']
    },
    {
        grant: 'DELETE',
        to: 'Administrator'
    }
];

annotate ProcurementService.RequisitionItems with @restrict: [
    {
        grant: 'READ',
        to: ['Requester', 'DepartmentManager', 'ITHead', 'FinanceApprover', 'CFO', 'ProcurementOfficer', 'Administrator', 'system-user']
    },
    {
        grant: ['CREATE', 'UPDATE', 'DELETE'],
        to: 'Requester',
        // where: (requisition.requesterId = $user)
    },
    {
        grant: ['READ', 'CREATE', 'UPDATE', 'DELETE'],
        to: 'Administrator'
    }
];

// Approval Tasks
annotate ProcurementService.ApprovalTasks with @restrict: [
    {
        grant: 'READ',
        to: ['DepartmentManager', 'ITHead', 'FinanceApprover', 'CFO', 'Requester', 'Administrator']
    }
];

// Approval Decisions
annotate ProcurementService.ApprovalDecisions with @restrict: [
    {
        grant: 'READ',
        to: ['DepartmentManager', 'ITHead', 'FinanceApprover', 'CFO', 'Requester', 'ProcurementOfficer', 'Administrator']
    }
];

// Attachments
annotate ProcurementService.Attachments with @restrict: [
    { grant: ['CREATE', 'READ', 'UPDATE', 'DELETE'], to: 'Requester' },
    { grant: 'READ', to: ['DepartmentManager', 'ITHead', 'FinanceApprover', 'CFO', 'ProcurementOfficer', 'Administrator'] }
];

// Actions
annotate ProcurementService.createPR with @(requires : 'Requester');
annotate ProcurementService.submitPR   with @(requires: 'Requester');
annotate ProcurementService.resubmitPR with @(requires: 'Requester');
annotate ProcurementService.cancelPR   with @(requires: 'Requester');

annotate ProcurementService.approvePR with @(requires: ['DepartmentManager', 'ITHead', 'FinanceApprover', 'CFO']);

annotate ProcurementService.rejectPR with @(requires: ['DepartmentManager', 'ITHead', 'FinanceApprover', 'CFO']);

annotate ProcurementService.returnPR with @(requires: ['DepartmentManager', 'ITHead', 'FinanceApprover', 'CFO']);

annotate ProcurementService.releasePR with @(requires: 'ProcurementOfficer');


