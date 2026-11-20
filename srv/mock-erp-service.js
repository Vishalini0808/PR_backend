const cds = require('@sap/cds');

module.exports = cds.service.impl(function () {

    this.on('postPR', async (req) => {

        const { prID, idempotencyKey, simulateFailure } = req.data;

        if (!prID || !idempotencyKey) {
            return req.error(400, 'PR ID and idempotency key are required');
        }

        if (simulateFailure) {
            return {
                status: 'FAILED',
                erpDocumentNumber: null,
                message: 'Mock ERP: simulated failure'
            };
        }

        return {
            status: 'SUCCESS',
            erpDocumentNumber: 'ERP-PR-' + cds.utils.uuid().slice(0, 8).toUpperCase(),
            message: 'Mock ERP: Purchase Requisition created successfully'
        };
    });

});