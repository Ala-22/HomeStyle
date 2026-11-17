import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../services/local_store_service.dart';
import '../services/notification_center.dart';

class CartScreen extends StatefulWidget {
  final LocalStoreService store;

  final bool Function(ProductModel) isFavorite;
  final void Function(ProductModel) onToggleFavorite;
  final ValueChanged<ProductModel> onProductTap;

  const CartScreen({
    super.key,
    required this.store,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onProductTap,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.store.getCart();

    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  double get _total {
    return _items.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  Future<void> _onQuantityChanged(CartItem item, int delta) async {
    final newQty = item.quantity + delta;

    if (newQty <= 0) return;

    await widget.store.updateQuantity(item.product.id, newQty);

    setState(() {
      item.quantity = newQty;
    });
  }

  Future<void> _onRemove(CartItem item) async {
    await widget.store.removeFromCart(item.product.id);

    setState(() {
      _items.removeWhere((i) => i.product.id == item.product.id);
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from cart'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _checkout() async {
    if (_items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Checkout'),
        content: Text(
          'Total: \$${_total.toStringAsFixed(2)}\n\n'
          'This is a demo checkout, no payment will be charged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final placedTotal = _total;
    final itemCount =
        _items.fold<int>(0, (sum, item) => sum + item.quantity);

    await widget.store.addOrder(total: placedTotal, itemCount: itemCount);
    await widget.store.clearCart();

    await NotificationCenter.instance.push(
      title: 'Order placed successfully 🎉',
      body:
          'Your order of \$${placedTotal.toStringAsFixed(2)} has been placed. '
          'You can track it from the Profile page.',
      icon: 'check_circle',
      colorIndex: 3,
    );

    if (!mounted) return;

    setState(() {
      _items = [];
    });

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 55,
        ),
        title: const Text('Order Placed! 🎉'),
        content: Text(
          'Thank you for your order.\nTotal: \$${placedTotal.toStringAsFixed(2)}',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping Cart (${_items.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _items.isEmpty ? null : _buildCheckoutBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 70,
              color: Colors.brown,
            ),
            const SizedBox(height: 15),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some products and they will show up here',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _CartItemTile(
          item: item,
          isFavorite: widget.isFavorite(item.product),
          onToggleFavorite: () => widget.onToggleFavorite(item.product),
          onTap: () => widget.onProductTap(item.product),
          onIncrease: () => _onQuantityChanged(item, 1),
          onDecrease: () => _onQuantityChanged(item, -1),
          onRemove: () => _onRemove(item),
        );
      },
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _checkout,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============ IMAGE ============
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.brown.shade50,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ============ INFO ============
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 21,
                        ),
                      ),
                    ],
                  ),

                  // ============ PRICE + QTY ============
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.hasDiscount
                                ? '\$${product.discountedPrice.toStringAsFixed(2)}'
                                : '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                          if (product.hasDiscount)
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          _QtyButton(
                            icon: Icons.remove,
                            onTap: onDecrease,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _QtyButton(
                            icon: Icons.add,
                            onTap: onIncrease,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.brown.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}