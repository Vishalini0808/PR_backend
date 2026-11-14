
namespace procurement.db;

using { cuid, managed } from '@sap/cds/common';

// COMMON TYPES

type Amount       : Decimal(15,2);
type Quantity     : Decimal(13,3);
type CurrencyCode : String(3);
type Percentage   : Decimal(5,2);

// ENUMS

type MasterStatus : String enum {
    Active   = 'ACTIVE';
    Inactive = 'INACTIVE';
}

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
    Rejected  = 'REJECTED';
    Returned  = 'RETURNED';
    Cancelled = 'CANCELLED';
}

type DecisionType : String enum {
    Approve = 'APPROVE';
    Reject  = 'REJECT';
    Return  = 'RETURN';
}

// COMMON STATUS ASPECT

aspect HasStatus {
    status : MasterStatus default #Active;
}


// ORGANIZATIONAL UNITS- department
entity OrganizationalUnits : cuid, managed, HasStatus {

    unitCode    : String(20) not null ;
    unitName    : String(100) not null;
    description : String(255);
   
}
annotate OrganizationalUnits with
    @assert.unique.unitCode: [unitCode];

// COST CENTRES - subdept of departments

entity CostCentres : cuid, managed, HasStatus {
    costCentreCode : String(30) not null;
    costCentreName : String(100) not null;
    description    : String(255);

    organizationalUnit : Association to OrganizationalUnits not null  @assert.target;
}

annotate CostCentres with @assert.unique.costCentreCode : [costCentreCode];

// PURCHASE CATEGORIES

entity PurchaseCategories : cuid, managed, HasStatus {
    categoryCode  : String(20) not null;
    categoryName  : String(100) not null;
    description   : String(255);
}

annotate PurchaseCategories with @assert.unique.categoryCode : [categoryCode];


// BUDGETS

entity Budgets : cuid, managed, HasStatus {
    budgetCode        : String(30) not null;
    financialYear     : Integer not null;
    allocatedAmount   : Amount not null;
    committedAmount   : Amount default 0;
    actualSpentAmount : Amount default 0;
    currency          : CurrencyCode default 'INR';

    costCentre : Association to CostCentres not null  @assert.target;
}

annotate Budgets with @assert.unique.budgetCode : [budgetCode];


// APPROVAL MATRIX

entity ApprovalMatrix : cuid, managed, HasStatus {
    matrixCode       : String(30) not null;
    approvalLevel    : Integer not null;
    sequenceNumber   : Integer not null;
    minimumAmount    : Amount not null;
    maximumAmount    : Amount;
    currency         : CurrencyCode default 'INR';
    approverRole     : String(50) not null;

    organizationalUnit : Association to OrganizationalUnits ;
    purchaseCategory   : Association to PurchaseCategories;
}

annotate ApprovalMatrix with @assert.unique.matrixCode : [matrixCode];


// DELIVERY LOCATIONS

entity DeliveryLocations : cuid, managed, HasStatus {
    locationCode : String(20) not null;
    locationName : String(100) not null;
    address      : String(255);
    city         : String(100);
    state        : String(100);
    postalCode   : String(20);
    country      : String(100);
}

annotate DeliveryLocations with @assert.unique.locationCode : [locationCode];


// PURCHASE REQUISITIONS

entity PurchaseRequisitions : cuid, managed {
    prNumber       : String(30);
    title          : String(150) not null; 
    description    : String(500);

    requesterId    : String(100) not null;
    requesterName  : String(100);
    requesterEmail : String(150) @assert.format: '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

    needByDate     : Date not null;
    currency       : CurrencyCode default 'INR';

    netAmount      : Amount default 0;
    taxAmount      : Amount default 0;
    totalAmount    : Amount default 0;

    status         : RequisitionStatus default #Draft;

    organizationalUnit : Association to OrganizationalUnits not null  @assert.target;
    costCentre         : Association to CostCentres not null @assert.target;
    purchaseCategory   : Association to PurchaseCategories not null  @assert.target;
    deliveryLocation   : Association to DeliveryLocations  @assert.target;

    items : Composition of many RequisitionItems
        on items.requisition = $self;

    approvalTasks : Composition of many ApprovalTasks
        on approvalTasks.requisition = $self;

    approvalDecisions : Composition of many ApprovalDecisions
        on approvalDecisions.requisition = $self;

    attachments : Composition of many Attachments
        on attachments.requisition = $self;
}

annotate PurchaseRequisitions with @assert.unique.prNumber : [prNumber];


// REQUISITION ITEMS

entity RequisitionItems : cuid, managed {
    itemNumber       : Integer;
    itemType         : ItemType @assert.enum;
    itemName         : String(150) not null;
    description      : String(500);

    materialCode     : String(50);
    quantity         : Quantity not null @assert.range: [0.01, 9999999999999.99];
    unitOfMeasure    : String(20);

    unitPrice        : Amount not null @assert.range: [0.01, 9999999999999.99];
    taxPercentage    : Percentage default 0 @assert.range: [0, 100];

    lineNetAmount    : Amount default 0;
    lineTaxAmount    : Amount default 0;
    lineTotalAmount  : Amount default 0;

    requisition : Association to PurchaseRequisitions not null  @assert.target;
}

// APPROVAL TASKS

entity ApprovalTasks : cuid, managed {
    taskNumber          : String(30);
    approvalLevel       : Integer not null;
    sequenceNumber      : Integer not null;
    approverRole        : String(50) not null;

    assignedApproverId   : String(100);
    assignedApproverName : String(100);

    dueDate             : Date;
    status              : ApprovalTaskStatus default #Pending;

    requisition : Association to PurchaseRequisitions not null  @assert.target;
}

annotate ApprovalTasks with @assert.unqiue.taskNumber : [taskNumber];


// APPROVAL DECISIONS

entity ApprovalDecisions : cuid, managed {
    decision       : DecisionType not null;
    decidedById    : String(100) not null;
    decidedByName  : String(100);
    comments       : String(500);
    decidedAt      : Timestamp;

    requisition : Association to PurchaseRequisitions not null  @assert.target;
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
