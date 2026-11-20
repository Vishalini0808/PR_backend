
namespace procurement.db;

using { cuid, managed } from '@sap/cds/common';

// COMMON TYPES

type Amount       : Decimal(15,2);
type Quantity     : Decimal(13,3);
type CurrencyCode : String(3);
type Percentage   : Decimal(5,2);

// ENUMS

type RequisitionStatus : String enum {
    Draft      = 'DRAFT';
    Submitted  = 'SUBMITTED';
    InApproval = 'IN_APPROVAL';
    Returned   = 'RETURNED';
    Rejected   = 'REJECTED';
    Approved   = 'APPROVED';
    Released   = 'RELEASED';
    Cancelled  = 'CANCELLED';
}

type ItemType : String enum {
    Material = 'MATERIAL';
    Service  = 'SERVICE';
}

type ApprovalTaskStatus : String enum {
    Pending   = 'PENDING';
    Approved  = 'APPROVED';
    Waiting   = 'WAITING';
    Rejected  = 'REJECTED';
    Returned  = 'RETURNED';
    Cancelled = 'CANCELLED';
}

type DecisionType : String enum {
    Approve = 'APPROVE';
    Reject  = 'REJECT';
    Return  = 'RETURN';
}

type ERPPublicationStatus : String enum {
    NotSent  = 'NOT_SENT';
    Pending  = 'PENDING';
    Success  = 'SUCCESS';
    Failed   = 'FAILED';
}


// PURCHASE REQUISITIONS

entity PurchaseRequisitions : cuid, managed {
    prNumber       : String(30) not null;
    title          : String(150) not null; 
    description    : String(500);

    requesterId    : String(100) ;
    requesterName  : String(100);
    requesterEmail : String(150) @assert.format: '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

    needByDate     : Date not null;
    currency       : CurrencyCode default 'INR';

    // calculated by backend
    netAmount      : Amount default 0;
    taxAmount      : Amount default 0;
    totalAmount    : Amount default 0;

    status         : RequisitionStatus default #Draft;

    // for resubmission
    currentCycle    : Integer default 0;

    // Master Data references - external UUIDs
    organizationalUnitID : UUID not null;
    costCentreID         : UUID not null;
    purchaseCategoryID   : UUID not null;
    deliveryLocationID   : UUID;
    projectReferenceID   : UUID;


    // child transaction records
    items : Composition of many RequisitionItems
        on items.requisition = $self;

    approvalTasks : Composition of many ApprovalTasks
        on approvalTasks.requisition = $self;

    attachments : Composition of many Attachments
        on attachments.requisition = $self;

    erpReference : Composition of one ERPReferences
        on erpReference.requisition = $self;
}

annotate PurchaseRequisitions with @assert.unique.prNumber : [prNumber];


// REQUISITION ITEMS

entity RequisitionItems : cuid, managed {
    itemNumber       : Integer;
    itemType         : ItemType @assert.enum;
    itemName         : String(150) not null;
    description      : String(500);

    materialCode     : String(50);
    quantity         : Quantity not null @assert.range: [0.01, 9999999999.999];
    unitOfMeasure    : String(20);

    unitPrice        : Amount not null @assert.range: [0.01, 9999999999999.99];
    taxPercentage    : Percentage default 0 @assert.range: [0, 100];
 
    // calculated by backend
    lineNetAmount    : Amount default 0;
    lineTaxAmount    : Amount default 0;
    lineTotalAmount  : Amount default 0;

    requisition : Association to PurchaseRequisitions not null ;
}

// APPROVAL TASKS

entity ApprovalTasks : cuid, managed {
    taskNumber          : String(30) not null;
    approvalLevel       : Integer not null;
    sequenceNumber      : Integer not null;
    approverRole        : String(50) not null;

    assignedApproverId   : String(100);
    assignedApproverName : String(100);

    dueDate             : Date;
    status              : ApprovalTaskStatus default #Pending;

    // resubmission
    submissionCycle : Integer default 1;      //

    requisition : Association to PurchaseRequisitions not null  @assert.target;

    decisions : Composition of many ApprovalDecisions on decisions.task = $self;
}

annotate ApprovalTasks with @assert.unique.taskNumber : [taskNumber];


// APPROVAL DECISIONS

entity ApprovalDecisions : cuid, managed {
    decision       : DecisionType not null;
    decidedById    : String(100) ;
    decidedByName  : String(100);
    comments       : String(500);
    decidedAt      : Timestamp not null @cds.on.insert: $now ;

    task        : Association to ApprovalTasks not null  @assert.target;
}

// ATTACHMENTS

entity Attachments : cuid, managed {
    fileName     : String(255) not null;
    mediaType    : String(100);
    fileSize     : Integer;
    content      : LargeBinary;
    uploadedBy   : String(100);

    requisition : Association to PurchaseRequisitions not null  @assert.target;
}

// ERP REFERENCES - ERP HAND-OFF


entity ERPReferences : cuid, managed {

    externalSystem       : String(50);

    externalDocumentNumber : String(50);
    externalPONumber       : String(50);

    publicationStatus : ERPPublicationStatus
        default #NotSent;

    idempotencyKey : String(100) not null;

    attemptCount   : Integer default 0;
    lastAttemptAt  : Timestamp;
    publishedAt    : Timestamp;

    errorMessage   : String(1000);

    requisition : Association to one PurchaseRequisitions
        not null;
}

annotate ERPReferences with @assert.unique.idempotencyKey: [idempotencyKey];

annotate ERPReferences with @assert.unique.requisition: [requisition];