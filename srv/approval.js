const cds = require('@sap/cds');
const { SELECT, UPDATE, INSERT } = cds.ql;

const {
    ApprovalTasks,
    ApprovalDecisions,
    PurchaseRequisitions
} = cds.entities('procurement.db');



// approve PR

async function approvePR(req) {

    // task id from req
    const { taskID, comments } = req.data;

    if (!taskID) {
        return req.reject(400, "Task ID required!")
    }

    const task = await SELECT.one.from(ApprovalTasks).where({
        ID: taskID
    });

    if (!task) {
        return req.reject(400, 'Task Not Found');
    }

    console.log("Task:", task)

    // check status of current task!
    if (task.status !== 'PENDING') {
        return req.reject(400, `Cannot Approve Task with the ${task.status} status`);
    }

    // check whether previous task is approved 
    const previousTask = await SELECT.one.from(ApprovalTasks)
        .where({
            requisition_ID: task.requisition_ID,
            sequenceNumber: { '<': task.sequenceNumber },
            status: { '!=': 'APPROVED' }
        });

    if (previousTask) {
        return req.reject(
            400,
            'Previous approval level must be completed first.'
        );
    }

    // create approval decision and comments

    const decisionID = cds.utils.uuid();

    await INSERT.into(ApprovalDecisions).entries({
        ID: decisionID,
        decision: 'APPROVE',
        decidedByName: req.data.decidedByName,
        decidedById: req.data.decidedById,
        comments: req.data.comments,
        task_ID: taskID
    });


    // update task status
    await UPDATE(ApprovalTasks).set({
        status: 'APPROVED'
    }).where({ ID: taskID });

    // fetch approved task
    const approvedTask = await SELECT.one.from(ApprovalTasks).where({
        ID: taskID
    });


    //  fetch next waiting next task:
    const nextTask = await SELECT.one.from(ApprovalTasks).where({
        requisition_ID: task.requisition_ID,
        status: 'WAITING',
        sequenceNumber: { '>': task.sequenceNumber }
    }).orderBy('sequenceNumber asc');

    let allApproved = false;

    if (nextTask) {

        // activate next task:

        await UPDATE(ApprovalTasks).set({
            status: 'PENDING'
        }).where({ ID: nextTask.ID });

        console.log("Next Approval task is Activated:", nextTask.ID);

    } else {

        // No more approval tasks- update PR -> approved
        await UPDATE(PurchaseRequisitions).set({
            status: 'APPROVED'
        }).where({
            ID: task.requisition_ID
        });

        allApproved = true;

        console.log("All approval levels are Completed!")
    }


    // Read PR current status
    const pr = await SELECT.one.from(PurchaseRequisitions)
        .columns('ID', 'status')
        .where({ ID: task.requisition_ID });


    return {
        taskID: approvedTask.ID,
        taskStatus: approvedTask.status,        // 'APPROVED'
        prID: pr.ID,
        prStatus: pr.status,
        nextTaskID: nextTask ? nextTask.ID : null,
        allApproved,
        message: allApproved
            ? 'Final approval completed. Purchase Requisition is approved.'
            : `Level ${task.sequenceNumber} approved. Next level is now pending.`
    };


}


// Reject PR

async function rejectPR(req) {

    const { taskID, comments } = req.data;

    // Validate task ID
    if (!taskID) {
        return req.reject(400, 'Task ID required!');
    }

    // Find approval task
    const task = await SELECT.one.from(ApprovalTasks)
        .where({ ID: taskID });

    if (!task) {
        return req.reject(404, 'Approval task not found!');
    }

    // Check task status
    if (task.status !== 'PENDING') {
        return req.reject(
            400,
            `Cannot reject task with ${task.status} status`
        );
    }

    // Create rejection decision
    const ID = cds.utils.uuid();
    await INSERT.into(ApprovalDecisions).entries({
        ID: ID,
        decision: 'REJECT',
        comments: comments,
        task_ID: taskID
    });

    // Update current task
    await UPDATE(ApprovalTasks)
        .set({ status: 'REJECTED' })
        .where({ ID: taskID });

    // Cancel remaining approval tasks
    await UPDATE(ApprovalTasks)
        .set({ status: 'CANCELLED' })
        .where({
            requisition_ID: task.requisition_ID,
            status: { in: ['PENDING', 'WAITING'] }
        });

    // Update PR status
    await UPDATE(PurchaseRequisitions)
        .set({ status: 'REJECTED' })
        .where({ ID: task.requisition_ID });

    console.log('PR Rejected:', task.requisition_ID);

}



async function returnPR(req) {

    const { taskID, comments } = req.data;

    // Validate task ID
    if (!taskID) {
        return req.reject(400, 'Task ID required!');
    }

    // Find approval task
    const task = await SELECT.one.from(ApprovalTasks)
        .where({ ID: taskID });

    if (!task) {
        return req.reject(404, 'Approval task not found!');
    }

    // Check task status
    if (task.status !== 'PENDING') {
        return req.reject(
            400,
            `Cannot return task with ${task.status} status`
        );
    }

    // Create approval decision
    await INSERT.into(ApprovalDecisions).entries({
        ID: cds.utils.uuid(),
        decision: 'RETURN',
        comments: comments,
        task_ID: taskID
    });

    // Update current task
    await UPDATE(ApprovalTasks)
        .set({ status: 'RETURNED' })
        .where({ ID: taskID });

    // Cancel remaining approval tasks
    await UPDATE(ApprovalTasks)
        .set({ status: 'CANCELLED' })
        .where({
            requisition_ID: task.requisition_ID,
            status: { in: ['PENDING', 'WAITING'] }
        });

    // Update PR status
    await UPDATE(PurchaseRequisitions)
        .set({ status: 'RETURNED' })
        .where({ ID: task.requisition_ID });

    console.log('PR Returned to Requester:', task.requisition_ID);
}



module.exports = { approvePR , rejectPR , returnPR };