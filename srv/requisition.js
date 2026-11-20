const cds = require('@sap/cds');
const { SELECT, UPDATE, INSERT } = cds.ql;


const {
    PurchaseRequisitions,
    RequisitionItems,
    ApprovalTasks
} = cds.entities('procurement.db');

let masterService;
let OrganizationalUnits;
let CostCentres;
let PurchaseCategories;
let DeliveryLocations;
let Budgets;
let ApprovalMatrix;
let ApproverAssignment;

// Initialize remote Master Data connection
async function connectMasterData() {

    if (!masterService) {
        masterService = await cds.connect.to('MasterDataService');

            console.log("Master service entity keys:");
        console.log(Object.keys(masterService.entities));

        console.log("Approver entity lookup:");
        console.log(
            masterService.entities['ApproverAssignment']
        );

        ({
            OrganizationalUnits,
            CostCentres,
            PurchaseCategories,
            DeliveryLocations,
            Budgets,
            ApprovalMatrix,
            ApproverAssignment
        } = masterService.entities);
    }
}


// create PR
async function createPR(req) {

    await connectMasterData();

    const data = req.data;

    // PR Header validations
    if (!data.title?.trim()) {
        return req.error(400, 'PR title is required.');
    }

    // if (!data.requesterId?.trim()) {
    //     return req.reject(400, 'Requester ID is required.');
    // }

    if (!data.requesterName?.trim()) {
        return req.error(400, 'Requester name is required.');
    }

    if (!data.requesterEmail?.trim()) {
        return req.error(400, 'Requester email is required.');
    }

    if (!data.organizationalUnitID) {
        return req.error(400, 'Please select an Organizational Unit.');
    }

    const orgUnit = await masterService.run(
        SELECT.one.from(OrganizationalUnits)
            .where({ ID: data.organizationalUnitID }));


    if (!orgUnit || orgUnit.status !== 'ACTIVE') {
        return req.error(400, 'Selected Organizational Unit does not exist or is inactive.');
    }

    if (!data.costCentreID) {
        return req.error(400, 'Please select a Cost Centre.');
    }

    const costCentre = await masterService.run(SELECT.one
        .from(CostCentres)
        .where({ ID: data.costCentreID }));

    if (!costCentre || costCentre.status !== 'ACTIVE') {
        return req.error(400, 'Selected Cost Centre does not exist or is inactive.');
    }

    if (costCentre.organizationalUnit_ID !== data.organizationalUnitID) {
        return req.error(400, 'Selected Cost Centre does not belong to the selected Organizational Unit.');
    }

    if (!data.purchaseCategoryID) {
        return req.error(400, 'Please select a Purchase Category.');
    }

    const category = await masterService.run(SELECT.one
        .from(PurchaseCategories)
        .where({ ID: data.purchaseCategoryID }));

    if (!category || category.status !== 'ACTIVE') {
        return req.error(400, 'Selected Purchase Category does not exist or is inactive.');
    }

    if (data.deliveryLocationID) {
        const location = await masterService.run(SELECT.one
            .from(DeliveryLocations)
            .where({ ID: data.deliveryLocationID }));

        if (!location || location.status !== 'ACTIVE') {
            return req.reject(400, 'Selected Delivery Location does not exist or is inactive.');
        }
    }

    const needByDate = new Date(data.needByDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (isNaN(needByDate.getTime()) || needByDate < today) {
        return req.error(400, 'Need-by date cannot be in the past');
    }

    if (!data.currency?.trim()) {
        return req.error(400, 'Currency is required.');
    }



    // Item validations
    const items = data.items || [];

    if (items.length === 0) {
        return req.error(400, 'Please add at least one PR item.');
    }

    let netAmount = 0;
    let taxAmount = 0


    for (const item of items) {

        if (!item.itemName?.trim()) {
            return req.error(400, 'Item name is required.');
        }

        if (!item.itemType) {
            return req.error(400, 'Item type is required.');
        }


        const tax = Number(item.taxPercentage ?? 0);

        if (!Number.isFinite(tax))
            return req.error(400, 'Tax percentage required.');

        // calculate item amounts
        const lineNet = Number((Number(item.quantity) * Number(item.unitPrice)).toFixed(2));
        const lineTax = Number((lineNet * tax / 100).toFixed(2));
        const lineTotal = Number((lineNet + lineTax).toFixed(2));

        item.lineNetAmount = lineNet;
        item.lineTaxAmount = lineTax;
        item.lineTotalAmount = lineTotal;

        netAmount += lineNet;
        taxAmount += lineTax;
    }

    // calculate PR header amounts
    data.netAmount = Number(netAmount.toFixed(2));
    data.taxAmount = Number(taxAmount.toFixed(2));
    data.totalAmount = Number((netAmount + taxAmount).toFixed(2));


    // generate PR number
    const lastPR = await SELECT.one.from(PurchaseRequisitions)
        .columns('prNumber')
        .orderBy({ prNumber: 'desc' });

    const lastNumber = lastPR?.prNumber ? Number(lastPR.prNumber.replace('PR', '')) : 1000;
    data.prNumber = `PR ${lastNumber + 1}`;

    // Initial status
    data.status = 'DRAFT';


    // Separate Header and Items

    delete data.items;

    //  Generate PR ID

    const prID = cds.utils.uuid();

    // Insert PR Header

    await INSERT.into(PurchaseRequisitions).entries({
        ...data,
        requesterId : req.user.id,
        ID: prID
    });


    // Insert PR Items

    const itemEntries = items.map(item => {

        return {
            ...item,
            ID: cds.utils.uuid(),
            requisition_ID: prID
        };

    });

    await INSERT.into(RequisitionItems).entries(itemEntries);


    //  Return Created PR

    const createdPR = await SELECT.one.from(PurchaseRequisitions)
        .where({ ID: prID });

    console.log(`PR with ID ${prID} successfully Created`)

    return createdPR;

}


// submit PR
async function submitPR(req) {

    await connectMasterData();

    const { prID } = req.data;
    console.log("PR ID:", prID);

    const data = req.data;

    // check whether pr exists
    const pr = await SELECT.one.from(PurchaseRequisitions).where({ ID: prID });

    if (!pr) {
        return req.reject(400, "PR not Found!");
    }

    // only allow to submit PR with the status DRAFT and RETURNED
    if (pr.status !== 'DRAFT' && pr.status !== 'RETURNED') {
        return req.reject(400, `Cannot Submit PR with the status ${pr.status}`);
    }


    // check PR header exists:
    if (!pr.prNumber) {
        return req.reject(400, "PR number Missing");
    }

    if (!pr.requesterId || !pr.requesterName || !pr.requesterEmail) {
        return req.reject(400, "Requester Details Missing");
    }

    if (pr.netAmount == null || pr.taxAmount == null || pr.totalAmount == null) {
        return req.reject(400, "PR Calculation fields Missing")
    }

    if (!pr.organizationalUnitID || !pr.costCentreID || !pr.purchaseCategoryID) {
        return req.reject(400, "PR Reference fileds missing")
    }

    // Saved Header Items validation
    const headerItems = await SELECT.from(RequisitionItems).where({ requisition_ID: prID })
    if (headerItems.length === 0) {
        return req.reject(400, "Please add atleast one PR item")
    }
    console.log("PR Header:", pr)

    // check fields for each items:
    for (let item of headerItems) {
        console.log("Items:", item)

        // Item name val
        if (!item.itemName?.trim()) {
            return req.reject(400, "Item name Required");
        }

        // item type
        if (!item.itemType) {
            return req.reject(400, "Item type required")
        }

        // Quantity validation
        if (item.quantity == null || Number(item.quantity) <= 0) {
            return req.reject(400, 'Item Quantity must be greater than Zero');
        }

        // Unit Price val
        if (item.unitPrice == null || Number(item.unitPrice) <= 0) {
            return req.reject(400, 'Item Unit Price must be greater than zero')
        }


    }

    // recalculate totAmount:
    let netAmount = 0;
    let taxAmount = 0;

    for (const item of headerItems) {

        const quantity = Number(item.quantity);
        const unitPrice = Number(item.unitPrice);
        const tax = Number(item.taxPercentage);

        if (!Number.isFinite(tax) || tax < 0 || tax > 100) {
            return req.reject(400, 'Tax percentage must be between 0 and 100.');
        }

        const lineNetAmount = Number((quantity * unitPrice).toFixed(2));
        const lineTaxAmount = Number((lineNetAmount * tax / 100).toFixed(2));
        const lineTotalAmount = Number((lineNetAmount + lineTaxAmount).toFixed(2));

        // Update in requisition items DB:
        await UPDATE(RequisitionItems).set({
            lineNetAmount,
            lineTaxAmount,
            lineTotalAmount
        }).where({ ID: item.ID });

        // add in headers in each item loop
        netAmount += lineNetAmount;
        taxAmount += lineTaxAmount;

    }

    // Calculate PR headers amounts
    netAmount = Number(netAmount.toFixed(2));
    taxAmount = Number(taxAmount.toFixed(2));

    const totalAmount = Number((netAmount + taxAmount).toFixed(2));

    // update in PR DB:
    await UPDATE(PurchaseRequisitions).set({
        netAmount,
        taxAmount,
        totalAmount
    }).where({ ID: prID });


    console.log("Budgets entity:", Budgets);
console.log("Master service entities:", Object.keys(masterService.entities));

    // Check budget
    const financialYear = new Date(pr.needByDate).getUTCFullYear();

    const budget = await masterService.run(
        SELECT.one.from(Budgets).where({
            costCentre_ID: pr.costCentreID,
            financialYear: financialYear,
            status: 'ACTIVE'

        })
    );

    console.log("Budget:", JSON.stringify(budget, null, 2));

    // calculate available budget
    if (!budget) {
        return req.reject(400, 'No active budget found for this cost centre and financial year!')
    }

    const allocatedAmount = Number(budget.allocatedAmount);
    const committedAmount = Number(budget.committedAmount);
    const actualSpentAmount = Number(budget.actualSpentAmount);

    const availableBudget = allocatedAmount - committedAmount - actualSpentAmount;

    console.log(`---available amount: ${availableBudget}---`)

    // recalculated pr amount vs available budget
    if (totalAmount > availableBudget) {
        return req.reject(400, `Insufficient budget!! Available: ${availableBudget} and Required:${pr.totalAmount}`);
    }

    console.log(`Budget validation successful`);

    // get matching approval matrix 
    const approvalRules = await masterService.run(
        SELECT.from(ApprovalMatrix).where`
            status = 'ACTIVE'
            and currency = ${pr.currency}
            and organizationalUnit_ID = ${pr.organizationalUnitID}
            and purchaseCategory_ID = ${pr.purchaseCategoryID}
            and minimumAmount <= ${totalAmount}
            and maximumAmount >= ${totalAmount}
        `.orderBy('sequenceNumber asc')
    );

    console.log("Matching Approval Rules:", approvalRules);

    if (!approvalRules || approvalRules.length === 0) {
        return req.reject(
            400,
            'No matching active Approval Matrix found for this PR.'
        );
    }

    // cycle
    const cycle = (pr.currentCycle ?? 0) + 1;

    // due date
    const firstTaskDueDate = new Date();
    firstTaskDueDate.setDate(firstTaskDueDate.getDate() + 3);

    // Create Approval task
    const approvalTaskEntries = await Promise.all(

        approvalRules.map(async (rule, index) => {

         const approver = await getAssignedApprover(rule, pr, req);

        return {
            taskNumber: `${pr.prNumber}-C${cycle}-A${rule.sequenceNumber}`,
            approvalLevel: rule.approvalLevel,
            sequenceNumber: rule.sequenceNumber,
            approverRole: rule.approverRole,
            
             // Employee fetched from ApproverAssignment
            assignedApproverId: approver.employeeId,
            assignedApproverName: approver.employeeName,

            submissionCycle: cycle,
            // status
            status: index === 0 ? 'PENDING' : 'WAITING',
            // Due date
            dueDate: index === 0 ? firstTaskDueDate : null,

            requisition_ID: prID
        };

    }));

    // insert all approval tasks

    await INSERT.into(ApprovalTasks).entries(approvalTaskEntries);

    // fetch the current cycle tasks:
    const approvalTasks = await SELECT.from(ApprovalTasks).where({
        requisition_ID: prID,
        submissionCycle: cycle
    }).orderBy('sequenceNumber asc');

    // created Approval tasks:
    console.log("Created Approval Tasks:", approvalTasks);


    // update PR status
    await UPDATE(PurchaseRequisitions).set({ status: 'IN_APPROVAL', currentCycle: cycle }).where({ ID: prID });

    console.log(`PR submitted successfully and approval workflow initiated`);

    return approvalTasks;

}

async function getAssignedApprover(rule, pr, req) {

    await connectMasterData();

    console.log("ApproverAssignment entity:", ApproverAssignment);
    console.log("Master service connected:", !!masterService);


    const conditions = {
        approverRole: rule.approverRole,
        organizationalUnit_ID: pr.organizationalUnitID,
        status: 'ACTIVE'
    };

    // First preference: category-specific assignment
    let assignments = await masterService.run(
        SELECT.from(ApproverAssignment).where({
            ...conditions,
            purchaseCategory_ID: pr.purchaseCategoryID
        })
    );

    // Second preference: general assignment (no category)
    if (assignments.length === 0) {

        assignments = await masterService.run(
            SELECT.from(ApproverAssignment).where({
                ...conditions,
                purchaseCategory_ID: null
            })
        );
    }

    // Validate assignment
    if (assignments.length === 0) {
        return req.reject(400, `No active employee assigned for role ${rule.approverRole}`);
    }

    if (assignments.length > 1) {
        return req.reject(400, `Multiple active employees found for role ${rule.approverRole}`);
    }

    return assignments[0];
}


// resubmit
async function resubmitPR(req) {

    const { prID } = req.data;

    if (!prID) {
        return req.reject(400, 'PR ID required!');
    }

    // Find PR
    const pr = await SELECT.one.from(PurchaseRequisitions)
        .where({ ID: prID });

    if (!pr) {
        return req.reject(404, 'Purchase Requisition not found!');
    }

    // Only returned PRs can be resubmitted
    if (pr.status !== 'RETURNED') {
        return req.reject(
            400,
            `Cannot resubmit PR with ${pr.status} status`
        );
    }

    if (pr.requesterId !== req.user.id) {
        return req.reject(403, 'Only the original requester can resubmit this PR.');
    }

    // Reuse existing submission logic
    return submitPR(req);
}


module.exports = {  createPR, submitPR, resubmitPR };