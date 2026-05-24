import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PurchasePaymentScreen extends StatefulWidget {
  final String url;
  final String orderId;
  const PurchasePaymentScreen({super.key, required this.url, required this.orderId});

  @override
  State<PurchasePaymentScreen> createState() => _PurchasePaymentScreenState();
}

class _PurchasePaymentScreenState extends State<PurchasePaymentScreen> {
  late final WebViewController _controller;
  bool isProcessing = false;

  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  void _listenToChatUpdates() {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
    _orderSubscription = orderRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      if (snapshot.exists && snapshot.data() != null) {
        final orderDoc = snapshot.data() as Map;

        if ((orderDoc['paid'] == true) && mounted) {
          await context.read<UserCubit>().onPurchasePlan(orderDoc);
          bool isGift = orderDoc['is_gift'] ?? false;
          if (isGift && mounted) {
            final receiver = await context.read<UserCubit>().getUserByRef(orderDoc['user']);
            if (mounted) context.replace('/payment_success', extra: receiver.name);
          } else {
            if (mounted) context.replace('/payment_success');
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (change) {
            print('*****onUrlChange: ${change.url}');
            if (change.url?.startsWith('https://telegram-app-kidscult.web.app') ?? false) {
              // Можно тут закрыть экран и проверить статус платежа
              // Navigator.of(context).pop(true); // true = оплата завершена
              print('***********Payment success redirect2');
              // context.replace('/payment_success');
              if (!isProcessing) {
                setState(() {
                  isProcessing = true;
                });
                _listenToChatUpdates();
              }
            }
          },
          // onNavigationRequest: (request) {
          //    print('*****onNavigationRequest: ${request.url}');
          //    if(request.url.startsWith(''))
          //    return NavigationDecision.navigate;
          // },
          onPageFinished: (url) {
            // if (url.startsWith('https://telegram-app-kidscult.web.app')) {
            //   // Можно тут закрыть экран и проверить статус платежа
            //   // Navigator.of(context).pop(true); // true = оплата завершена
            //   print('***********Payment success redirect');
            //   // context.replace('/payment_success');
            //   if (!isProcessing) {
            //     setState(() {
            //       isProcessing = true;
            //     });
            //     _listenToChatUpdates();
            //   }
            // }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: white,
        body: isProcessing ? processingLoading() : WebViewWidget(controller: _controller),
      ),
    );
  }

  Widget processingLoading() {
    return Container(
      constraints: const BoxConstraints.expand(),
      color: Colors.black38,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 45),
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              AppText(
                text: 'purchase_loading'.tr(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
