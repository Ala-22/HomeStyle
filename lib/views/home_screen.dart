import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/local_store_service.dart';
import '../services/notification_center.dart';
import '../services/preferences_service.dart';
import '../viewmodels/product_viewmodel.dart';
import 'ai_designer_screen.dart';
import 'cart_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

const Color _brown = Color(0xFF6D4C41);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductViewModel _viewModel = ProductViewModel();
  final LocalStoreService _store = LocalStoreService();

  final List<String> categories = [
    'All',
    'AI Images',
    'Kitchen',
    'Guest Room',
    'Bedrooms',
    'Living Room',
    'Bathroom',
    'Kitchen Tools',
    'General Tools',
    'Bathroom Tools',
  ];

  String selectedCategory = 'All';

  int selectedNavigationIndex = 0;

  List<ProductModel> favoriteProducts = [];
  List<CartItem> cartItems = [];

  String userName = 'HomeStyle User';
  String userEmail = '';
  int userId = 0;

  bool _productsNotificationSent = false;

  @override
  void initState() {
    super.initState();

    NotificationCenter.instance.load();        // ① حمّل الإشعارات المحفوظة

    _viewModel.addListener(_refresh);          // ② اشترك بالتغييرات
    _viewModel.fetchProducts();                  // ③ اجيب المنتجات من الـ API

    _loadUser();
    _loadLocalData();                // ⑤ اجيب المفضلة والسلة
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }

    if (!_viewModel.isLoading &&
        _viewModel.products.isNotEmpty &&
        !_productsNotificationSent) {
      _productsNotificationSent = true;

      NotificationCenter.instance.push(
        title: 'New products added',
        body:
            '${_viewModel.products.length} fresh products are now available '
            'across all categories.',
        icon: 'new',
        colorIndex: 0,
      );
    }
  }

  Future<void> _loadUser() async {
    final name = await PreferencesService.getUserName();
    final email = await PreferencesService.getUserEmail();
    final id = await PreferencesService.getUserId();

    if (!mounted) return;

    setState(() {
      userName = name ?? 'HomeStyle User';
      userEmail = email ?? '';
      userId = id ?? 0;
    });
  }

  Future<void> _loadLocalData() async {
    List<ProductModel> favorites = [];
    List<CartItem> cart = [];

    try {
      favorites = await _store.getFavorites();
      cart = await _store.getCart();
    } catch (_) {
      // local database unavailable: keep in-memory empty lists
    }

    if (!mounted) return;

    setState(() {
      favoriteProducts = favorites;
      cartItems = cart;
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    super.dispose();
  }

  // =========================
  // DERIVED
  // =========================

  List<ProductModel> get filteredProducts {
    if (selectedCategory == 'All') {
      return _viewModel.products;
    }

    return _viewModel.products
        .where((product) => product.category == selectedCategory)
        .toList();
  }

  int get cartCount {
    return cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

List<ProductModel> get newDesigns => _viewModel.products
    .where((p) => p.category == 'AI Images')
    .toList();

  bool isFavorite(ProductModel product) {
    return favoriteProducts.any((p) => p.id == product.id);
  }

  bool isInCart(ProductModel product) {
    return cartItems.any((i) => i.product.id == product.id);
  }

  // =========================
  // ACTIONS
  // =========================

  Future<void> toggleFavorite(ProductModel product) async {
    final added = await _store.toggleFavorite(product);

    if (!mounted) return;

    setState(() {
      if (added) {
        favoriteProducts = [...favoriteProducts, product];
      } else {
        favoriteProducts =
            favoriteProducts.where((p) => p.id != product.id).toList();
      }
    });

    if (added) {
      NotificationCenter.instance.push(
        title: 'Added to Favorites ❤️',
        body: '${product.name} is now saved in your favorites.',
        icon: 'favorite',
        colorIndex: 4,
      );
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added ? 'Added to Favorites ❤️' : 'Removed from Favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  Future<void> addToCart(ProductModel product) async {
    final wasInCart = isInCart(product);

    await _store.addToCart(product);

    final cart = await _store.getCart();

    if (!mounted) return;

    setState(() {
      cartItems = cart;
    });

    if (!wasInCart) {
      NotificationCenter.instance.push(
        title: 'Added to Cart 🛒',
        body: '${product.name} was added to your shopping cart.',
        icon: 'shopping_cart',
        colorIndex: 0,
      );
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isInCart(product) ? 'Added to Cart 🛒' : 'Already in your cart',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  void openDetails(ProductModel product) {
    final similar = _viewModel.products
        .where((p) => p.category == product.category && p.id != product.id)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          product: product,
          isFavorite: isFavorite(product),
          isInCart: isInCart(product),
          onFavorite: () => toggleFavorite(product),
          onAddToCart: () => addToCart(product),
          similarProducts: similar,
          onSimilarTap: openDetails,
        ),
      ),
    );
  }

  void _openNewDesignsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(
          title: 'AI Images ✨',
          products: newDesigns,
          emptyMessage:
              'No AI images yet.\nGenerate a design in the AI tab and tap '
              '"Add to AI Images" to save it here.',
          isFavorite: isFavorite,
          isInCart: isInCart,
          onFavorite: toggleFavorite,
          onAddToCart: addToCart,
          onRemoveFromCart: (product) {},
          onProductTap: openDetails,
        ),
      ),
    );
  }

  Widget _buildNewDesignsSection(BuildContext context) {
    final items = newDesigns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AI Images ✨',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _openNewDesignsPage,
              child: const Text('See All'),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.brown.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.brown.shade200),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    color: Colors.brown),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your AI images will appear here',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Generate a design in the AI tab and tap '
                        '"Add to AI Images ✨", or drop images inside '
                        'the "AI Images" folder on this laptop.',
                        style: TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = items[index];

                return _NewDesignCard(
                  product: product,
                  onTap: () => openDetails(product),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showAllProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(
          title: selectedCategory == 'All'
              ? 'All Products'
              : selectedCategory,
          products: filteredProducts,
          emptyMessage: 'No products in this category yet',
          isFavorite: isFavorite,
          isInCart: isInCart,
          onFavorite: toggleFavorite,
          onAddToCart: addToCart,
          onRemoveFromCart: (product) {},
          onProductTap: openDetails,
        ),
      ),
    );
  }

  void showCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          store: _store,
          isFavorite: isFavorite,
          onToggleFavorite: toggleFavorite,
          onProductTap: openDetails,
        ),
      ),
    ).then((_) => _loadLocalData());
  }

  void showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  void showSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          products: _viewModel.products,
          isFavorite: isFavorite,
          isInCart: isInCart,
          onToggleFavorite: toggleFavorite,
          onAddToCart: addToCart,
          onProductTap: openDetails,
        ),
      ),
    );
  }

  void showAIDesigner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIDesignerScreen(),
      ),
    );
  }

  void showFavoritesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(
          title: 'Favorites ❤️',
          products: favoriteProducts,
          emptyMessage: 'No favorite products yet',
          isFavorite: isFavorite,
          isInCart: isInCart,
          onFavorite: toggleFavorite,
          onAddToCart: addToCart,
          onRemoveFromCart: (product) {},
          onProductTap: openDetails,
        ),
      ),
    ).then((_) => _loadLocalData());
  }

  Future<void> logout() async {
    await PreferencesService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (userId > 0) {
      try {
        await ApiService().deleteAccount(userId: userId);
      } catch (_) {
        // server unreachable: still sign the user out locally
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your account has been deleted'),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    await PreferencesService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  int getGridColumns(
    double width, {
    required bool allProducts,
  }) {
    if (allProducts) {
      if (width >= 1400) return 5;
      if (width >= 1000) return 4;
      if (width >= 650) return 3;
      return 2;
    } else {
      if (width >= 1400) return 4;
      if (width >= 900) return 3;
      return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showFavoritesTab = selectedNavigationIndex == 1;
    final bool showAIPage = selectedNavigationIndex == 2;
    final bool showProfilePage = selectedNavigationIndex == 3;

    final String appBarTitle = showFavoritesTab
        ? 'My Favorites ❤️'
        : showAIPage
            ? 'AI Room Designer'
            : showProfilePage
                ? 'Profile'
                : 'HomeStyle';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: showSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Cart',
                onPressed: showCart,
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$cartCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          ListenableBuilder(
            listenable: NotificationCenter.instance,
            builder: (context, _) {
              final unread = NotificationCenter.instance.unreadCount;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: showNotifications,
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.brown,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      // =====================================================
      // DRAWER
      // =====================================================

      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(25, 30, 25, 26),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'http://localhost/homestyle_api/images/'
                      'Living%20Room/1.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              _brown.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.home_rounded,
                              size: 35, color: _brown),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'HomeStyle',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Welcome, $userName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (userEmail.isNotEmpty)
                          Text(
                            userEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedNavigationIndex = 0;
                    selectedCategory = 'All';
                  });
                },
              ),

              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('AI Room Designer'),
                onTap: () {
                  Navigator.pop(context);
                  showAIDesigner();
                },
              ),

              ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined),
                title: Text('AI Images ✨ (${newDesigns.length})'),
                onTap: () {
                  Navigator.pop(context);
                  _openNewDesignsPage();
                },
              ),

              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: Text('Favorites (${favoriteProducts.length})'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedNavigationIndex = 1;
                  });
                },
              ),

              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: Text('Cart ($cartCount)'),
                onTap: () {
                  Navigator.pop(context);
                  showCart();
                },
              ),

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedNavigationIndex = 3;
                  });
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  logout();
                },
              ),
            ],
          ),
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: Stack(
        fit: StackFit.expand,
        children: [
          if (selectedNavigationIndex == 0) const _HomeBackdrop(),

          showFavoritesTab
          ? ProductListContent(
              title: 'My Favorites ❤️',
              products: favoriteProducts,
              emptyMessage:
                  'You have no favorite products yet.\nTap the heart on any product.',
              isFavorite: isFavorite,
              isInCart: isInCart,
              onFavorite: toggleFavorite,
              onAddToCart: addToCart,
              onRemoveFromCart: (product) {},
              onProductTap: openDetails,
            )
          : showAIPage
              ? const AIDesignerBody()
              : showProfilePage
                  ? ProfileContent(
                      name: userName,
                      email: userEmail,
                      userId: userId,
                      favoritesCount: favoriteProducts.length,
                      onLogout: logout,
                      onDeleteAccount: deleteAccount,
                      onFavoritesTap: showFavoritesPage,
                      store: _store,
                    )
                  : RefreshIndicator(
                      onRefresh: _viewModel.fetchProducts,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final products = filteredProducts;
                          final bool allProducts =
                              selectedCategory == 'All';

                          return ListView(
                            padding: const EdgeInsets.all(18),
                            children: [
                              // =====================================
                              // HERO BANNER
                              // =====================================
                              ClipPath(
                                clipper: HomeBannerClipper(),
                                child: Container(
                                  height: 215,
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    25,
                                    20,
                                    25,
                                    85,
                                  ),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF4E342E),
                                        Color(0xFF6D4C41),
                                        Color(0xFF8D6E63),
                                      ],
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        right: -35,
                                        top: -45,
                                        child: Container(
                                          width: 150,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.07),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 45,
                                        bottom: 15,
                                        child: Container(
                                          width: 85,
                                          height: 85,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.05),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Welcome back 👋',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            userName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Beautiful ideas for your home',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // =====================================
                              // SEARCH BAR
                              // =====================================
                              Transform.translate(
                                offset: const Offset(0, -30),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Material(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface,
                                    borderRadius: BorderRadius.circular(18),
                                    elevation: 4,
                                    shadowColor: Colors.black26,
                                    child: InkWell(
                                      onTap: showSearch,
                                      borderRadius:
                                          BorderRadius.circular(18),
                                      child: Container(
                                        height: 56,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.search_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Search for furniture, décor...',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.tune_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // =====================================
                              // AI BANNER
                              // =====================================
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedNavigationIndex = 2;
                                  });
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Ink(
                                  height: 96,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF5D4037),
                                        Color(0xFF8D6E63),
                                      ],
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(18),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '✨ AI Room Designer',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Generate your dream room with AI',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              // =====================================
                              // NEW DESIGNS SECTION
                              // =====================================

                              _buildNewDesignsSection(context),

                              const SizedBox(height: 25),

                              // =====================================
                              // CATEGORIES
                              // =====================================

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Categories',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _showAllProducts,
                                    child: const Text('See All'),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              SizedBox(
                                height: 43,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: categories.length,
                                  itemBuilder: (context, index) {
                                    final category = categories[index];
                                    final selected =
                                        category == selectedCategory;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 9,
                                      ),
                                      child: ChoiceChip(
                                        label: Text(category),
                                        selected: selected,
                                        onSelected: (_) {
                                          setState(() {
                                            selectedCategory = category;
                                            selectedNavigationIndex = 0;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 25),

                              // =====================================
                              // PRODUCTS HEADER
                              // =====================================

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    allProducts
                                        ? 'Popular Products'
                                        : selectedCategory,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _showAllProducts,
                                    child: const Text('See All'),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // =====================================
                              // LOADING
                              // =====================================

                              if (_viewModel.isLoading)
                                const Padding(
                                  padding: EdgeInsets.all(50),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )

                              // =====================================
                              // ERROR
                              // =====================================

                              else if (_viewModel.errorMessage != null)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.cloud_off_outlined,
                                          size: 45,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _viewModel.errorMessage!,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )

                              // =====================================
                              // EMPTY
                              // =====================================

                              else if (products.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(30),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 45,
                                        ),
                                        SizedBox(height: 10),
                                        Text('No products found'),
                                      ],
                                    ),
                                  ),
                                )

                              // =====================================
                              // PRODUCTS
                              // =====================================

                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: products.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: getGridColumns(
                                      constraints.maxWidth,
                                      allProducts: allProducts,
                                    ),
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 16,
                                    childAspectRatio:
                                        allProducts ? 1.05 : 0.82,
                                  ),
                                  itemBuilder: (context, index) {
                                    final product = products[index];

                                    return ProductCard(
                                      product: product,
                                      favorite: isFavorite(product),
                                      inCart: isInCart(product),
                                      onTap: () =>
                                          openDetails(product),
                                      onFavorite: () =>
                                          toggleFavorite(product),
                                      onAddToCart: () =>
                                          addToCart(product),
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ),
        ],
      ),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedNavigationIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedNavigationIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// PRODUCT CARD
// =====================================================

class ProductCard extends StatelessWidget {
  final ProductModel product;

  final bool favorite;
  final bool inCart;

  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.favorite,
    required this.inCart,
    required this.onTap,
    required this.onFavorite,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // IMAGE
            // =====================================================

            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 35,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),

                  // OFF BADGE
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '20% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // FAVORITE
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onFavorite,
                        icon: Icon(
                          favorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: favorite
                              ? Colors.redAccent
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),

                  // CART
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onAddToCart,
                        icon: Icon(
                          inCart
                              ? Icons.shopping_cart
                              : Icons.shopping_cart_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =====================================================
            // INFO
            // =====================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // RATING ROW
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB300),
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviewsCount})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // PRICE ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.priceLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          '\$${product.oldPrice!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
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

// =====================================================
// PRODUCT DETAILS
// =====================================================

class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;

  final bool isFavorite;
  final bool isInCart;

  final VoidCallback onFavorite;
  final VoidCallback onAddToCart;

  final List<ProductModel> similarProducts;
  final void Function(ProductModel) onSimilarTap;

  static void _noOp(ProductModel product) {}

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.isInCart,
    required this.onFavorite,
    required this.onAddToCart,
    this.similarProducts = const [],
    this.onSimilarTap = _noOp,
  });

  String getDescription() {
    switch (product.category) {
      case 'Kitchen':
        return 'A beautiful kitchen item designed to add style, comfort and functionality to your home.';
      case 'Living Room':
        return 'A stylish living room piece that can help create a warm, modern and comfortable space.';
      case 'Bedrooms':
        return 'A beautiful bedroom item designed to make your space more elegant, relaxing and comfortable.';
      case 'Guest Room':
        return 'A practical and elegant piece perfect for creating a welcoming guest room.';
      case 'Bathroom':
        return 'A modern bathroom item designed to add functionality and an elegant touch to your bathroom.';
      case 'Bathroom Tools':
        return 'A useful bathroom accessory that combines practicality with a clean and beautiful design.';
      case 'Kitchen Tools':
        return 'A useful kitchen tool designed to make everyday tasks easier while keeping your kitchen organized.';
      case 'General Tools':
        return 'A practical home accessory that can be useful in different areas of your home.';
      default:
        return 'A beautiful HomeStyle product carefully selected to help you create the home you love.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: onFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // IMAGE
            // =====================================================

            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported_outlined,
                            size: 60,
                          );
                        },
                      ),
                      if (product.hasDiscount)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '20% OFF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =====================================================
            // CATEGORY
            // =====================================================

            Text(
              product.category,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 7),

            // =====================================================
            // NAME
            // =====================================================

            Text(
              product.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // =====================================================
            // RATING
            // =====================================================

            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB300),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${product.rating}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${product.reviewsCount} reviews)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // =====================================================
            // PRICE
            // =====================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.priceLabel,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (product.hasDiscount) ...[
                  const SizedBox(width: 10),
                  Text(
                    '\$${product.oldPrice!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'About this product',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              getDescription(),
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 30),

            // =====================================================
            // ADD TO CART
            // =====================================================

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onAddToCart,
                icon: Icon(
                  isInCart
                      ? Icons.shopping_cart
                      : Icons.shopping_cart_outlined,
                ),
                label: Text(
                  isInCart ? 'Added to Cart' : 'Add to Cart',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // =====================================================
            // FAVORITE BUTTON
            // =====================================================

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                label: Text(
                  isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                ),
              ),
            ),

            // =====================================================
            // SIMILAR PRODUCTS
            // =====================================================

            if (similarProducts.isNotEmpty) ...[
              const SizedBox(height: 32),

              const Text(
                'Similar Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 175,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: similarProducts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final similar = similarProducts[index];

                    return _SimilarProductCard(
                      product: similar,
                      onTap: () => onSimilarTap(similar),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================
// PRODUCT LIST SCREEN
// =====================================================

class ProductListScreen extends StatelessWidget {
  final String title;
  final List<ProductModel> products;
  final String emptyMessage;

  final bool Function(ProductModel) isFavorite;
  final bool Function(ProductModel) isInCart;
  final void Function(ProductModel) onFavorite;
  final void Function(ProductModel) onAddToCart;
  final void Function(ProductModel) onRemoveFromCart;
  final void Function(ProductModel) onProductTap;

  const ProductListScreen({
    super.key,
    required this.title,
    required this.products,
    required this.emptyMessage,
    required this.isFavorite,
    required this.isInCart,
    required this.onFavorite,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ProductListContent(
        title: title,
        products: products,
        emptyMessage: emptyMessage,
        isFavorite: isFavorite,
        isInCart: isInCart,
        onFavorite: onFavorite,
        onAddToCart: onAddToCart,
        onRemoveFromCart: onRemoveFromCart,
        onProductTap: onProductTap,
      ),
    );
  }
}

// =====================================================
// PRODUCT LIST CONTENT
// =====================================================

class ProductListContent extends StatelessWidget {
  final String title;
  final List<ProductModel> products;
  final String emptyMessage;

  final bool Function(ProductModel) isFavorite;
  final bool Function(ProductModel) isInCart;
  final void Function(ProductModel) onFavorite;
  final void Function(ProductModel) onAddToCart;
  final void Function(ProductModel) onRemoveFromCart;
  final void Function(ProductModel) onProductTap;

  const ProductListContent({
    super.key,
    required this.title,
    required this.products,
    required this.emptyMessage,
    required this.isFavorite,
    required this.isInCart,
    required this.onFavorite,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_border,
                size: 65,
                color: Colors.brown,
              ),
              const SizedBox(height: 15),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;

        if (constraints.maxWidth >= 1200) {
          columns = 4;
        } else if (constraints.maxWidth >= 800) {
          columns = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final product = products[index];

            return ProductCard(
              product: product,
              favorite: isFavorite(product),
              inCart: isInCart(product),
              onTap: () => onProductTap(product),
              onFavorite: () => onFavorite(product),
              onAddToCart: () => onAddToCart(product),
            );
          },
        );
      },
    );
  }
}

// =====================================================
// HOME BACKDROP (REAL ROOM PHOTO)
// =====================================================

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  static const String _imageUrl =
      'http://localhost/homestyle_api/images/Living%20Room/1.jpg';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _imageUrl,
          fit: BoxFit.cover,
          opacity: AlwaysStoppedAnimation(isDark ? 0.20 : 0.32),
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox.shrink(),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF1D140E).withValues(alpha: 0.80),
                      const Color(0xFF1D140E).withValues(alpha: 0.92),
                    ]
                  : [
                      const Color(0xFFF7EFE5).withValues(alpha: 0.74),
                      const Color(0xFFF7EFE5).withValues(alpha: 0.90),
                    ],
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// CLIPPER
// =====================================================

class HomeBannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height - 30);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 20,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 5,
      size.width,
      size.height - 30,
    );

    path.lineTo(size.width, 0);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

// =====================================================
// SIMILAR PRODUCT CARD
// =====================================================

class _SimilarProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _SimilarProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 28,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.priceLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// NEW DESIGN CARD
// =====================================================

class _NewDesignCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _NewDesignCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.brown.shade200,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 105,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 28,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),

                    // NEW badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fiber_new_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 13,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Your design',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.priceLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}