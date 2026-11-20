const cds = require('@sap/cds');
const { submitPR, createPR, resubmitPR } = require("./requisition");
const { approvePR, rejectPR, returnPR } = require("./approval");
const { releasePR } = require('./procurement');

module.exports = cds.service.impl(async function () {

    const { PurchaseRequisitions } = this.entities;

    // CreatePR
    // this.before('CREATE', PurchaseRequisitions, validatePR);
    this.on('createPR', createPR);

    // resubmit
    this.on('resubmitPR', resubmitPR);

    // cancel submitted
    // this.on('cancelPR', cancelPR);

    // SubmitPR
    this.on('submitPR', submitPR);


    // Approve PR
    this.on('approvePR', approvePR);

    // rejection PR
    this.on('rejectPR', rejectPR);

    // Return PR for correction
    this.on('returnPR', returnPR);


    // release PR
    this.on('releasePR', releasePR);

});