const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Cloud Function để gửi push notifications
 * Trigger: Khi có document mới trong collection 'notifications'
 */
exports.sendPushNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        try {
            const data = snap.data();
            const targetEmployeeId = data.targetEmployeeId;
            const title = data.title;
            const body = data.body;
            const notificationData = data.data || {};

            // Lấy FCM token của employee
            const employeeDoc = await admin.firestore()
                .collection('employees')
                .doc(targetEmployeeId)
                .get();

            if (!employeeDoc.exists) {
                console.log(`Employee ${targetEmployeeId} not found`);
                await snap.ref.update({ status: 'failed', error: 'Employee not found' });
                return null;
            }

            const employee = employeeDoc.data();
            const fcmToken = employee.fcmToken;

            if (!fcmToken) {
                console.log(`Employee ${targetEmployeeId} has no FCM token`);
                await snap.ref.update({ status: 'failed', error: 'No FCM token' });
                return null;
            }

            // Gửi notification
            const message = {
                notification: {
                    title: title,
                    body: body,
                },
                data: notificationData,
                token: fcmToken,
            };

            const response = await admin.messaging().send(message);
            console.log('Successfully sent message:', response);

            // Update status
            await snap.ref.update({
                status: 'sent',
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                messageId: response
            });

            return response;
        } catch (error) {
            console.error('Error sending notification:', error);
            await snap.ref.update({
                status: 'failed',
                error: error.message,
                failedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            return null;
        }
    });

/**
 * Cloud Function để cleanup notifications cũ (optional)
 * Chạy mỗi ngày lúc 2AM
 */
exports.cleanupOldNotifications = functions.pubsub
    .schedule('0 2 * * *')
    .timeZone('Asia/Ho_Chi_Minh')
    .onRun(async (context) => {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const snapshot = await admin.firestore()
            .collection('notifications')
            .where('createdAt', '<', thirtyDaysAgo)
            .get();

        const batch = admin.firestore().batch();
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        await batch.commit();
        console.log(`Deleted ${snapshot.size} old notifications`);
        return null;
    });
