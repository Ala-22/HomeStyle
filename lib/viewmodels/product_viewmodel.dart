import 'package:flutter/foundation.dart';

import '../models/product_model.dart';

import '../services/api_service.dart';



class ProductViewModel extends ChangeNotifier {

  final ApiService _apiService = ApiService();



  List<ProductModel> products = [];



  bool isLoading = false;

  String? errorMessage;



  Future<void> fetchProducts() async {

    isLoading = true;

    errorMessage = null;

    notifyListeners();



    try {

      products = await _apiService.getProducts();

    } catch (e) {

      errorMessage = 'Failed to load products';

    }



    isLoading = false;

    notifyListeners();

  }

}

