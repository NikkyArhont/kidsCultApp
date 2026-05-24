import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchasesProvider extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // static const String productId = 'month_standart';
  static const Set<String> _kProductIds = <String>{'month_standart', 'month_base', 'month_premium'};

  bool _isAvailable = false;
  bool _isLoading = true;
  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];
  String? _errorMessage;

  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  String? get errorMessage => _errorMessage;

  InAppPurchasesProvider() {
    _initialize();
  }

  /// initialize
  Future<void> _initialize() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;

    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        _handleError('error purchase stream: $error');
      },
    );

    // check availability
    await _checkAvailability();

    // load products
    if (_isAvailable) {
      await _loadProducts();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// check availability
  Future<void> _checkAvailability() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        _errorMessage = 'shop not available';
      }
    } catch (e) {
      _handleError('error checking availability: $e');
    }
  }

  /// load products
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kProductIds);

      if (response.error != null) {
        _handleError('error loading products: ${response.error}');
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        _handleError('products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;

      notifyListeners();
    } catch (e) {
      _handleError('error loading products: $e');
    }
  }

  /// handle purchase update
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchaseUpdate(purchaseDetails);
    }
  }

  /// handle purchase update
  Future<void> _handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    print('get purchase update: ${purchaseDetails.productID}, status: ${purchaseDetails.status}');

    if (purchaseDetails.status == PurchaseStatus.pending) {
      print('pending purchase: ${purchaseDetails.productID}');
    } else {
      if (purchaseDetails.status == PurchaseStatus.error) {
        _handleError('error purchase: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        print('handle new purchase: ${purchaseDetails.productID}');

        bool valid = await _verifyPurchase(purchaseDetails);

        if (valid) {
          await _deliverProduct(purchaseDetails);
        } else {
          _handleInvalidPurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        print('purchase restored: ${purchaseDetails.productID}');
      }

      if (purchaseDetails.pendingCompletePurchase) {
        print('complete purchase: ${purchaseDetails.productID}');
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }

    notifyListeners();
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    print('product delivered: ${purchaseDetails.productID}');

    _purchases.add(purchaseDetails);

    notifyListeners();
  }

  /// handle invalid purchase
  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    _handleError('invalid purchase: ${purchaseDetails.productID}');
  }

  /// handle error
  void _handleError(String error) {
    debugPrint('error: $error');
    _errorMessage = error;
    notifyListeners();
  }

  /// buy product
  Future<bool> buyProduct(ProductDetails productDetails) async {
    if (!_isAvailable) {
      _handleError('shop not available');
      return false;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _handleError('error buying product: $e');
      return false;
    }
  }

  /// bay add balance method
  Future<bool> buySubs(String planId) async {
    final product = _products.firstWhere((product) => product.id == planId);

    return await buyProduct(product);
  }

  /// clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
