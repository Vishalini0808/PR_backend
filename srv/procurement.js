const cds = require('@sap/cds');
const { SELECT, INSERT, UPDATE } = cds.ql;
const { executeHttpRequest } = require('@sap-cloud-sdk/http-client');

const BPA_DESTINATION = 'PR_Release_BPA';
const BPA_DEFINITION_ID = 'us10.5a566441trial.prreleaseprocess.pR_Release_Process';

async function releasePR(req) {
    const { prID } = req.data;

    if (!prID) return req.error(400, 'Purchase Requisition ID is required');
    if (!req.user.is('ProcurementOfficer')) {
        return req.error(403, 'Only Procurement Officers can release PRs');
    }

    const { PurchaseRequisitions, ERPReferences } = cds.entities('procurement.db');

    // Phase 1: validate and mark PENDING in its own short transaction.
    // It commits before BPA is called, so a fast callback finds the row.
    const check = await cds.tx(async (tx) => {
        const pr = await tx.run(
            SELECT.one.from(PurchaseRequisitions).where({ ID: prID }).forUpdate()
        );
        if (!pr) return { code: 404, msg: 'Purchase Requisition not found' };
        if (pr.status !== 'APPROVED') {
            return { code: 400, msg: 'Only APPROVED PRs can be released' };
        }

        const ref = await tx.run(
            SELECT.one.from(ERPReferences).where({ requisition_ID: prID })
        );
        if (ref?.publicationStatus === 'SUCCESS') {
            return { code: 409, msg: 'PR is already released to ERP' };
        }
        if (ref?.publicationStatus === 'PENDING') {
            return { code: 409, msg: 'ERP release is already in progress' };
        }

        if (!ref) {
            await tx.run(INSERT.into(ERPReferences).entries({
                ID: cds.utils.uuid(),
                requisition_ID: prID,
                externalSystem: 'MOCK_ERP',
                publicationStatus: 'PENDING',
                idempotencyKey: cds.utils.uuid(),
                attemptCount: 1,
                lastAttemptAt: new Date()
            }));
        } else {
            await tx.run(
                UPDATE(ERPReferences)
                    .set({
                        publicationStatus: 'PENDING',
                        attemptCount: (ref.attemptCount || 0) + 1,
                        lastAttemptAt: new Date(),
                        errorMessage: null
                    })
                    .where({ requisition_ID: prID })
            );
        }
        return { ok: true };
    });

    if (!check.ok) return req.error(check.code, check.msg);

    // Phase 2: start the BPA process through the destination.

    let bpaResponse;

    try {
        bpaResponse = await executeHttpRequest(
            { destinationName: BPA_DESTINATION },
            {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                data: { definitionId: BPA_DEFINITION_ID, context: { prid: prID } }
            }
        );
    } catch (err) {
        cds.log('releasePR').error('BPA start failed:', err.response?.status, err.message);
        await cds.tx(async (tx) => tx.run(
            UPDATE(ERPReferences).set({ publicationStatus: 'FAILED' }).where({ requisition_ID: prID })
        ));
        return req.error(502, 'Could not start the ERP release process. Status set to FAILED, you can retry.');
    }

    const workflowID = bpaResponse.data.id;

    cds.log('releasePR').info(
        `BPA workflow started: ${workflowID}`
    );

    return { message: 'ERP release started', prID };
}

module.exports = { releasePR };