using {procurement.db as db} from '../db/purchaseRequisitionSchema';

@path: '/procurement'
@requires: 'authenticated-user'
service ProcurementService {

    // Purchase Requisition
   
    entity PurchaseRequisitions as projection on db.PurchaseRequisitions;

    entity RequisitionItems     as projection on db.RequisitionItems;

    // Approval
    entity ApprovalTasks        as projection on db.ApprovalTasks;

    entity ApprovalDecisions    as projection on db.ApprovalDecisions;

    // Attachments
    entity Attachments          as projection on db.Attachments;

    entity ERPReferences as projection on db.ERPReferences;


    // PR Actions

    action createPR(
    title                : String,
    description          : String,
    requesterName        : String,
    requesterEmail       : String,
    organizationalUnitID : UUID,
    costCentreID         : UUID,
    purchaseCategoryID   : UUID,
    deliveryLocationID   : UUID,
    needByDate           : Date,
    currency             : String,

    items : many {
        itemNumber      : Integer;
        itemName        : String;
        description     : String;
        itemType        : String;
        materialCode    : String;
        quantity        : Decimal(15,2);
        unitOfMeasure   : String;
        unitPrice       : Decimal(15,2);
        taxPercentage   : Decimal(5,2);
    }

) returns PurchaseRequisitions;

    action submitPR(prID: UUID) returns many ApprovalTasks;

    action resubmitPR(prID: UUID) returns many ApprovalTasks;

    action cancelPR(prID: UUID, reason: String(500));


    // Approval Actions
    type ApprovePRResult {
        taskID      : UUID;
        taskStatus  : String;
        prID        : UUID;
        prStatus    : String;
        nextTaskID  : UUID; // null when this was the last level
        allApproved : Boolean;
        message     : String;
    }

    action approvePR(taskID: UUID,
                     comments: String(500)) returns ApprovePRResult;

    action rejectPR(taskID: UUID,
                    comments: String(500));

    action returnPR(taskID: UUID,
                    comments: String(500));


    // Procurement Action

    action releasePR(prID: UUID);


    action createERPPurchaseRequisition(prID: UUID) returns String;


}
