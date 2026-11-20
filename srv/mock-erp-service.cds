@path: '/mock-erp'
@requires: 'authenticated-user'
service MockERPService {

    action postPR(
        prID: String(36),
        idempotencyKey: String(100),
        simulateFailure: Boolean
    )
    returns {
        status: String(20);
        erpDocumentNumber: String(50);
        message: String(255);
    };
}