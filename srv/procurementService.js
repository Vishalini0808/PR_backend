const cds  = require('@sap/cds');
const {submitPR ,validatePR } = require("./requisition")

module.exports = cds.service.impl( async function() {

    const { PurchaseRequisitions } = this.entities;

    // CreatePR- validation
    this.before('CREATE', PurchaseRequisitions, validatePR);


    // SubmitPR
    this.on('submitPR',submitPR);

});