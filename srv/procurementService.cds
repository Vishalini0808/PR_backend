
using procurement.db as db from '../db/purchaseRequisitionSchema';

service ProcurementService {

    // Master Data
    entity OrganizationalUnits as projection on db.OrganizationalUnits;
    entity CostCentres         as projection on db.CostCentres;
    entity PurchaseCategories as projection on db.PurchaseCategories;
    entity DeliveryLocations  as projection on db.DeliveryLocations;
    entity Budgets            as projection on db.Budgets;
    entity ApprovalMatrix     as projection on db.ApprovalMatrix;

    // Purchase Requisition
    entity PurchaseRequisitions as projection on db.PurchaseRequisitions;
    entity RequisitionItems     as projection on db.RequisitionItems;

    // Approval
    entity ApprovalTasks      as projection on db.ApprovalTasks;
    entity ApprovalDecisions  as projection on db.ApprovalDecisions;

    // Attachments
    entity Attachments as projection on db.Attachments;


    
    // PR actions

    action submitPR(prID : UUID);

    action resubmitPR(prID : UUID);

    action cancelPR(
        prID   : UUID,
        reason : String(500)
    );


    // approval actions

    action approvePR( taskID : UUID, comments : String(500));

    action rejectPR(taskID : UUID, comments : String(500));

    action returnPR(taskID : UUID, comments : String(500));


    // procurement action

    action releasePR(prID : UUID);


    // calculation functions

    function calculatePRTotal(prID : UUID)
        returns Decimal(15,2);

    function checkBudget(prID : UUID)
        returns Boolean;


}
