import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../views/home_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<ProductModel> products;
  final bool Function(ProductModel) isFavorite;
  final bool Function(ProductModel) isInCart;
  final void Function(ProductModel) onToggleFavorite;
  final void Function(ProductModel) onAddToCart;
  final void Function(ProductModel) onProductTap;

  const SearchScreen({
    super.key,
    required this.products,
    required this.isFavorite,
    required this.isInCart,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.onProductTap,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  String _query = '';

  List<ProductModel> get _results {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) return [];

    return widget.products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search furniture, rooms...',
            border: InputBorder.none,
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _query = '';
                      });
                    },
                  ),
          ),
        ),
      ),
      body: results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _query.isEmpty
                        ? Icons.search
                        : Icons.search_off,
                    size: 65,
                    color: Colors.brown.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _query.isEmpty
                        ? 'Start typing to search'
                        : 'No results for "$_query"',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                int columns = 2;

                if (constraints.maxWidth >= 1000) columns = 4;
                if (constraints.maxWidth >= 650) columns = 3;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final product = results[index];

                    return ProductCard(
                      product: product,
                      favorite: widget.isFavorite(product),
                      inCart: widget.isInCart(product),
                      onTap: () => widget.onProductTap(product),
                      onFavorite: () =>
                          widget.onToggleFavorite(product),
                      onAddToCart: () => widget.onAddToCart(product),
                    );
                  },
                );
              },
            ),
    );
  }
}