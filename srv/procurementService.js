const cds  = require('@sap/cds');
const {submitPR ,validatePR, resubmitPR  } = require("./requisition")
const { approvePR,  rejectPR , returnPR } = require("./approval")

module.exports = cds.service.impl( async function() {

    const { PurchaseRequisitions } = this.entities;

    // CreatePR- validation
    this.before('CREATE', PurchaseRequisitions, validatePR);

    // resubmit
    this.on('resubmitPR', resubmitPR);

    // cancel submitted
    // this.on('cancelPR', cancelPR);

    // SubmitPR
    this.on('submitPR',submitPR);


    // Approve PR
    this.on('approvePR',approvePR);

    // rejection PR
    this.on('rejectPR', rejectPR);

    // Return PR for correction
    this.on('returnPR', returnPR);

});