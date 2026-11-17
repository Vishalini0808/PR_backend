using  ProcurementService  from './procurementService';

annotate ProcurementService.PurchaseRequisitions with @restrict : [
        {
            grant: 'READ',
            to: ['Requester', 'DepartmentManager', 'FinanceApprover', 'ProcurementOfficer', 'Administrator']
        },
        {
            grant: ['CREATE', 'UPDATE'],
            to: ['Requester', 'Administrator']
            // where: (requesterId = $user)
        },
        {
            grant: 'DELETE',
            to: 'Administrator'
        }
];

annotate ProcurementService.RequisitionItems with @restrict : [
    {
        grant: 'READ',
        to: ['Requester', 'DepartmentManager', 'FinanceApprover', 'ProcurementOfficer', 'Administrator']
    },
    {
        grant: ['CREATE', 'UPDATE', 'DELETE'],
        to: 'Requester',
        where: (requisition.requesterId = $user)
    },
    {
        grant: ['READ', 'CREATE', 'UPDATE', 'DELETE'],
        to: 'Administrator'
    }
];

// Tasks and decisions are changed only by the actions, so only READ is granted
annotate ProcurementService.ApprovalTasks with @restrict: [
    { grant: 'READ', to: ['DepartmentManager', 'FinanceApprover', 'Requester' ,'Administrator'] }
];

annotate ProcurementService.ApprovalDecisions with @restrict: [
    { grant: 'READ', to: ['DepartmentManager', 'FinanceApprover', 'Requester', 'ProcurementOfficer' ,'Administrator'] }
];

annotate ProcurementService.Attachments with @restrict: [
    { grant: ['CREATE','READ','UPDATE','DELETE'], to: 'Requester' },
    { grant: 'READ', to: ['DepartmentManager','FinanceApprover','ProcurementOfficer','Administrator'] }
];


// Actions
annotate ProcurementService.submitPR   with @(requires: 'Requester');
annotate ProcurementService.resubmitPR with @(requires: 'Requester');
annotate ProcurementService.cancelPR   with @(requires: 'Requester');

annotate ProcurementService.approvePR  with @(requires: ['DepartmentManager','FinanceApprover']);
annotate ProcurementService.rejectPR   with @(requires: ['DepartmentManager','FinanceApprover']);
annotate ProcurementService.returnPR   with @(requires: ['DepartmentManager','FinanceApprover']);

annotate ProcurementService.releasePR  with @(requires: 'ProcurementOfficer');