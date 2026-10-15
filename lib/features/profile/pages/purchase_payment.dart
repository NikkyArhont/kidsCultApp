import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PurchasePaymentScreen extends StatefulWidget {
  final String url;
  final String orderId;
  const PurchasePaymentScreen({super.key, required this.url, required this.orderId});

  @override
  State<PurchasePaymentScreen> createState() => _PurchasePaymentScreenState();
}

class _PurchasePaymentScreenState extends State<PurchasePaymentScreen> with WidgetsBindingObserver {
  WebViewController? _controller;
  bool isProcessing = false;
  bool _handled = false;
  bool _checking = false;
  String? _error;
  bool _canceled = false;
  Timer? _statusTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _orderSubscription;

  void _listenToOrder() {
    if (_orderSubscription != null) return;
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
    _orderSubscription = orderRef.snapshots().listen(_handleOrder, onError: (Object error) {
      _showError('Не удалось получить статус оплаты. Повторите проверку.');
    });
  }

  Future<void> _handleOrder(DocumentSnapshot<Map<String, dynamic>> snapshot) async {
    final order = snapshot.data();
    if (!mounted || order == null || _handled) return;
    if (order['status'] == 'canceled') {
      sl<PaymentService>().forgetPayment(widget.orderId);
      _statusTimer?.cancel();
      setState(() {
        _canceled = true;
        _error = 'Оплата отменена. Подписка не была оплачена.';
        isProcessing = true;
      });
      return;
    }
    // A redirect or a paid flag alone cannot prove the subscription was issued.
    if (order['paid'] != true || order['fulfilled'] != true) return;
    sl<PaymentService>().forgetPayment(widget.orderId);
    _handled = true;
    try {
      final userCubit = context.read<UserCubit>();
      await userCubit.onPurchasePlan({...order, 'id': snapshot.id});
      String? receiverName;
      if (order['is_gift'] == true) {
        final receiver = await userCubit.getUserByRef(order['user'] as DocumentReference);
        receiverName = receiver.name;
      }
      if (!mounted) return;
      _statusTimer?.cancel();
      context.replace('/payment_success', extra: receiverName);
    } catch (_) {
      _handled = false;
      _showError('Оплата подтверждена. Не удалось обновить профиль, повторите проверку.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      isProcessing = true;
    });
  }

  Future<void> _checkPayment() async {
    if (_checking || _handled || _canceled || !mounted) return;
    _checking = true;
    try {
      await sl<PaymentService>().refreshPayment(widget.orderId);
      if (mounted && !_handled && !_canceled) setState(() => _error = null);
      final snapshot = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get(
            const GetOptions(source: Source.server),
          );
      await _handleOrder(snapshot);
    } catch (_) {
      _showError('Проверка оплаты временно недоступна. Не оплачивайте заказ повторно; повторите проверку.');
    } finally {
      _checking = false;
    }
  }

  Future<void> _openExternalPayment() async {
    if (widget.url.isEmpty) return;
    try {
      final opened = await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
      if (!opened) _showError('Не удалось открыть страницу оплаты.');
    } catch (_) {
      _showError('Не удалось открыть страницу оплаты.');
    }
  }

  Future<void> _resumePayment() async {
    if (!mounted || _handled || _canceled || widget.url.isEmpty) return;
    if (kIsWeb) {
      await _openExternalPayment();
      return;
    }
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _error = null;
      isProcessing = false;
    });
    try {
      // Reopen this order's checkout, never create a second payment on retry.
      await controller.loadRequest(Uri.parse(widget.url));
    } catch (_) {
      _showError('Не удалось загрузить страницу оплаты.');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToOrder();
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkPayment());
    if (kIsWeb || widget.url.isEmpty) {
      isProcessing = true;
      _openExternalPayment();
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onUrlChange: (change) {
            final uri = Uri.tryParse(change.url ?? '');
            if (uri?.host == 'telegram-app-kidscult.web.app' || uri?.host == 'kidscult-a5d7e.web.app') {
              if (mounted) setState(() => isProcessing = true);
              _checkPayment();
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              _showError('Не удалось загрузить страницу оплаты.');
            }
          },
        ))
        ..loadRequest(Uri.parse(widget.url));
    }
    _checkPayment();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPayment();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _orderSubscription?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: white,
        appBar: AppBar(leading: BackButton(onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/current_subscription');
          }
        })),
        body: isProcessing || _controller == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error == null) const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(_error ?? 'purchase_loading'.tr(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      if (!_canceled) TextButton(onPressed: _checkPayment, child: const Text('Проверить оплату')),
                      if (widget.url.isNotEmpty && !_canceled && !_handled)
                        TextButton(
                          onPressed: _resumePayment,
                          child: const Text(kIsWeb ? 'Открыть страницу оплаты' : 'Продолжить оплату'),
                        ),
                    ],
                  ),
                ),
              )
            : WebViewWidget(controller: _controller!),
      ),
    );
  }
}
