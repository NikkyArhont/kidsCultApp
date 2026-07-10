const functions = require("firebase-functions");
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');


const initial_payment_msg = "Списываем оплату за подписку";
const my_url = "https://telegram-app-kidscult.web.app/#/payment_web_redirect/";

const shopId = '1139805';
const secretKey = 'test_0i3a0kJVk9GCJaUc4wcu-Ui1ncyuTSAuHoCvoMp0yok';
const authHeader = Buffer.from(`${shopId}:${secretKey}`).toString('base64');

exports.initialPayment = functions.https.onCall(async (request) => {

    const { order_id } = request.data;

    try {
        const url = "https://api.yookassa.ru/v3/payments";

        const orders = admin.firestore().collection('orders');
        var order_snapshot = await orders.doc(order_id).get();
        var order = order_snapshot.data();
        var price = order['price'];

        // параметры для запроса
        var headers = {
            'Authorization': `Basic ${authHeader}`,
            "Idempotence-Key": uuidv4().toString(),
            "Content-Type": 'application/json'
        };
        var params = {
            "amount": {
                "value": price.toString(),
                "currency": "RUB"
            },
            "payment_method_data": {
                "type": "bank_card"
            },
            "confirmation": {
                "type": "redirect",
                "return_url": `${my_url}?orderId=${order_id}`
            },
            "description": initial_payment_msg,
            "save_payment_method": "false"
        };

        const response = await axios.post(url, params, { headers: headers });

        const res = response.data;

        if (res.status == "pending") {
            await orders.doc(order_id).update({ "payment_id": res.payment_method.id });

            return {
                "url": res.confirmation.confirmation_url,
            };
        }

    } catch (e) {
        functions.logger.log("ERROR");
        functions.logger.log(e.message);
        return {
            "status": "error",
            "body": e.message
        }
    }
});


exports.UkassaWebHook = functions.https.onRequest(async (request, response) => {
    if (request.body.event == "payment.waiting_for_capture") {
        let payment_id = request.body.object.id;
        let status = request.body.object.status;
        if (status == "waiting_for_capture") {

            await _confirmPayment(payment_id);
            await _getPayment(payment_id);
        }
    }
    response.send("OK");
});




const _confirmPayment = async (payment_id) => {
    await admin.firestore().collection('orders').where("payment_id", "==", payment_id)
        .limit(1)
        .get()
        .then(snapshot => {
            if (snapshot.size > 0) {
                const firstDoc = snapshot.docs[0].ref;
                firstDoc.update({ paid: true }).then(() => {
                    console.log('Документ успешно обновлен');
                })
                    .catch(err => {
                        console.log('Ошибка обновления документа', err);
                    });
            } else {
                console.log("документы не найдены");
            }
        })
        .catch(err => {
            console.log('Ошибка получения документа', err);
            return null
        });
}

const _getPayment = async (payment_id) => {
    const url = `https://api.yookassa.ru/v3/payments/${payment_id}/capture`;

    var headers = {
        'Authorization': `Basic ${authHeader}`,
        "Idempotence-Key": uuidv4().toString(),
        "Content-Type": 'application/json'
    };

    return await axios.post(url, {}, {
        headers: headers,
    }).then((res) => res.data).then(async (res) => {
        functions.logger.log("Платеж успешно подтвержден", res);
        return true;
    }).catch((err) => {
        functions.logger.log("Ошибка при подтверждении платежа", err);
        return false;
    });
}

// const cancelPayemnt = async (payment_id) => {
//     const url = `https://api.yookassa.ru/v3/payments/${payment_id}/cancel`;

//     var headers = {
//         "Authorization": authorization,
//         "Idempotence-Key": uuidv4().toString(),
//         "Content-Type": 'application/json'
//     };

//     return await axios.post(url, {}, {
//         headers: headers,
//     }).then((res) => res.data).then(async (res) => {
//         functions.logger.log("Платеж успешно отменен", res);
//         return true;
//     }).catch((err) => {
//         functions.logger.log("Ошибка при отмене платежа", err);
//         return false;
//     });
// }

// exports.getPaymentApi = functions.https.onRequest(async (request, response) => {
//     var payment_id = request.body.payment_id;
//     await getPayment(payment_id);
//     response.status(200);
// });

// exports.cancelPaymentApi = functions.https.onRequest(async (request, response) => {
//     var payment_id = request.body.payment_id;
//     await cancelPayemnt(payment_id);
//     response.status(200);
// })