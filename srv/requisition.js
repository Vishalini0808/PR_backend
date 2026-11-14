const { SELECT } = require("@sap/cds/lib/ql/cds-ql");
const UPDATE = require("@sap/cds/lib/ql/UPDATE");


const {
    PurchaseRequisitions,
    RequisitionItems,
    OrganizationalUnits,
    CostCentres,
    PurchaseCategories,
    DeliveryLocations } = cds.entities('procurement.db');

// create PR
async function validatePR(req) {


    const data = req.data;

    // PR Header validations
    if (!data.title?.trim()) {
        return req.error(400, 'PR title is required.');
    }

    if (!data.requesterId?.trim()) {
        return req.reject(400, 'Requester ID is required.');
    }

    if (!data.requesterName?.trim()) {
        return req.error(400, 'Requester name is required.');
    }

    if (!data.requesterEmail?.trim()) {
        return req.error(400, 'Requester email is required.');
    }

    if (!data.organizationalUnit_ID) {
        return req.error(400, 'Please select an Organizational Unit.');
    }

    const orgUnit = await SELECT.one
        .from(OrganizationalUnits)
        .where({ ID: data.organizationalUnit_ID });

    if (!orgUnit || orgUnit.status !== 'ACTIVE') {
        return req.error(400, 'Selected Organizational Unit does not exist or is inactive.');
    }

    if (!data.costCentre_ID) {
        return req.error(400, 'Please select a Cost Centre.');
    }

    const costCentre = await SELECT.one
        .from(CostCentres)
        .where({ ID: data.costCentre_ID });

    if (!costCentre || costCentre.status !== 'ACTIVE') {
        return req.error(400, 'Selected Cost Centre does not exist or is inactive.');
    }

    if (costCentre.organizationalUnit_ID !== data.organizationalUnit_ID) {
        return req.error(400, 'Selected Cost Centre does not belong to the selected Organizational Unit.');
    }

    if (!data.purchaseCategory_ID) {
        return req.error(400, 'Please select a Purchase Category.');
    }

    const category = await SELECT.one
        .from(PurchaseCategories)
        .where({ ID: data.purchaseCategory_ID });

    if (!category || category.status !== 'ACTIVE') {
        return req.error(400, 'Selected Purchase Category does not exist or is inactive.');
    }

    if (data.deliveryLocation_ID) {
        const location = await SELECT.one
            .from(DeliveryLocations)
            .where({ ID: data.deliveryLocation_ID });

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
    data.prNumber = `PR${lastNumber + 1}`;

    // Initial status
    data.status = 'DRAFT';

}



// submit PR
async function submitPR(req) {

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
        req.error(400, "PR number Missing");
    }

    if (!pr.requesterId || !pr.requesterName || !pr.requesterEmail) {
        req.error(400, "Requester Details Missing");
    }

    if (pr.netAmount == null || pr.taxAmount == null || pr.totalAmount == null) {
        req.error(400, "PR Calculation fields Missing")
    }

    if (!pr.organizationalUnit_ID || !pr.costCentre_ID || !pr.purchaseCategory_ID) {
        req.error(400, "PR Reference fileds missing")
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
            req.error(400, "Item name Required");
        }

        // item type
        if (!item.itemType) {
            req.error(400, "Item type required")
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



    // Check budget:


}


module.exports = { submitPR, validatePR };