const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall } = require('firebase-functions/v2/https');

admin.initializeApp();
const db = admin.firestore();

const { sendPushNotificationToUser } = require('./sendPush');
const payments = require('./payment');

exports.initialPayment = payments.initialPayment;
exports.ukassaWebHook = payments.UkassaWebHook;

exports.checkOverdueTasks = onSchedule('0 0,12 * * *', // ⏰ Каждый день в 00:00 и 12:00
    {
        timeZone: 'Europe/Moscow', // 🌍 Московский часовой пояс
    }, async (event) => {
        const now = admin.firestore.Timestamp.now();

        console.log(`Проверка просроченных задач. Текущее время: ${now.toDate()}`);

        try {
            const snapshot = await db.collection('tasks')
                .where('status', 'in', ['inProgress', 'onReview', 'needsRework'])
                .where('type', '!=', 'kid')
                .where('end_date', '<', now)
                .get();

            const batch = db.batch();
            let updatedCount = 0;

            snapshot.forEach(doc => {
                const data = doc.data();
                if (data.type !== 'kid' && data.end_date) {
                    batch.update(doc.ref, {
                        status: 'canceled',
                        cancel_reason: 'out_of_deadline'
                    });
                    console.log(`Задача ${doc.id} помечена как просроченная`);
                    updatedCount++;
                }
            });

            if (updatedCount > 0) {
                await batch.commit();
                console.log(`Обновлено ${updatedCount} просроченных задач.`);
            } else {
                console.log('Просроченных задач не найдено.');
            }

            return null;
        } catch (error) {
            console.error('Ошибка при проверке просроченных задач:', error);
            return null;
        }
    });



exports.checkOverdueTasksTest = functions.https.onRequest(async (req, res) => {
    if (req.method !== 'POST' && req.method !== 'GET') {
        res.status(405).send('Method Not Allowed');
        return;
    }

    const now = admin.firestore.Timestamp.now();

    console.log(`ТЕСТ: Проверка просроченных задач. Текущее время: ${now.toDate()}`);

    try {
        const snapshot = await db.collection('tasks')
            .where('status', 'in', ['inProgress', 'onReview', 'needsRework'])
            .where('type', '!=', 'kid')
            .where('end_date', '<', now)
            .get();

        const batch = db.batch();
        let updatedCount = 0;
        const updatedTasks = [];

        snapshot.forEach(doc => {
            const data = doc.data();
            if (data.type !== 'kid' && data.end_date) {
                batch.update(doc.ref, {
                    status: 'canceled',
                    cancel_reason: 'out_of_deadline'
                });
                updatedTasks.push({
                    id: doc.id,
                    title: data.title || 'Без названия',
                    end_date: data.end_date ? data.end_date.toDate() : null
                });
                updatedCount++;
            }
        });

        if (updatedCount > 0) {
            await batch.commit();
            console.log(`ТЕСТ: Обновлено ${updatedCount} просроченных задач.`);
            res.status(200).json({
                success: true,
                message: `Обновлено ${updatedCount} просроченных задач`,
                updatedTasks: updatedTasks
            });
        } else {
            console.log('ТЕСТ: Просроченных задач не найдено.');
            res.status(200).json({
                success: true,
                message: 'Просроченных задач не найдено'
            });
        }

    } catch (error) {
        console.error('ТЕСТ: Ошибка при проверке просроченных задач:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 📲 HTTPS Callable для Flutter
exports.sendPushNotificationToUser = onCall(async (request) => {
    const { userId, title, body = '', data = {} } = request.data;

    try {
        const messageId = await sendPushNotificationToUser(userId, title, body, data);
        return { success: true, messageId };
    } catch (error) {
        console.error('Ошибка при отправке push:', error);
        return { success: false, error: error.message };
    }
});

// Cloud Function для отправки напоминаний
exports.sendReminders = functions.https.onRequest(async (req, res) => {
    try {
        const now = new Date();
        const currentMinutes = now.getUTCMinutes();
        const currentHours = now.getUTCHours();
        const currentTime = now.toISOString().slice(0, 16); // YYYY-MM-DDTHH:mm
        const currentDay = (now.getUTCDay() + 6) % 7; // Преобразуем: ВС=6, ПН=0, ..., СБ=5

        // Запрашиваем задачи с активными статусами и напоминаниями
        const tasksSnapshot = await admin
            .firestore()
            .collection("tasks")
            .where("status", "in", ["inProgress", "onReview", "needsRework"])
            // .where('type', '!=', 'kid')
            .limit(1000) // Ограничение для масштабирования
            .get();

        const batch = admin.firestore().batch();

        for (const taskDoc of tasksSnapshot.docs) {
            const task = taskDoc.data();
            const taskId = taskDoc.id;

            // Проверяем, нужно ли отправить напоминание
            let shouldSend = false;
            if (task.reminder_type === "single" && task.reminder_date) {
                const reminderDate = task.reminder_date.toDate().toISOString().slice(0, 16);
                if (reminderDate === currentTime) {
                    shouldSend = true;
                }
            } else if (task.reminder_type === "daily" && task.reminder_time && task.reminder_days && task.reminder_days.length > 0) {
                const reminderTime = task.reminder_time.toDate();
                if (
                    reminderTime.getUTCHours() === currentHours &&
                    reminderTime.getUTCMinutes() === currentMinutes &&
                    task.reminder_days.includes(currentDay)
                ) {
                    shouldSend = true;
                }
            }

            if (!shouldSend) continue;

            // Получаем данные ребенка
            const kidDoc = await task.kid.get();
            if (!kidDoc.exists) {
                console.log(`Kid for task ${taskId} not found`);
                continue;
            }

            const kid = kidDoc.data();
            if (!kid.notification || !kid.fcm_token) {
                console.log(`Notifications disabled or no FCM token for kid ${task.kid.id}`);
                continue;
            }

            // Отправляем пуш
            const message = {
                notification: {
                    title: "Время выполнить задание:",
                    body: `"${task.name}"`,
                },
                data: {
                    type: "reminder",
                    task_id: taskId,
                },
                token: kid.fcm_token,
            };

            try {
                await admin.messaging().send(message);
                console.log(`Sent push for task ${taskId} to ${kid.fcm_token}`);
            } catch (error) {
                console.error(`Error sending push for task ${taskId}:`, error);
            }
        }

        // Применяем обновления (отключение single напоминаний)
        await batch.commit();
        res.status(200).send("Reminders processed");
    } catch (error) {
        console.error("Error processing reminders:", error);
        res.status(500).send("Error processing reminders");
    }
});