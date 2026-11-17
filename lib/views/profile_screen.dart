import 'package:flutter/material.dart';

import '../services/local_store_service.dart';
import 'orders_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String name;
  final String email;
  final int userId;
  final int favoritesCount;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final VoidCallback onFavoritesTap;
  final LocalStoreService store;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.userId,
    required this.favoritesCount,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onFavoritesTap,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ProfileContent(
        name: name,
        email: email,
        userId: userId,
        favoritesCount: favoritesCount,
        onLogout: onLogout,
        onDeleteAccount: onDeleteAccount,
        onFavoritesTap: onFavoritesTap,
        store: store,
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  final String name;
  final String email;
  final int userId;
  final int favoritesCount;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final VoidCallback onFavoritesTap;
  final LocalStoreService store;

  const ProfileContent({
    super.key,
    required this.name,
    required this.email,
    required this.userId,
    required this.favoritesCount,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onFavoritesTap,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : 'U';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // ============================
              // HEADER / USER CARD
              // ============================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.isEmpty ? 'No email' : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ============================
              // FAVORITES STAT
              // ============================
              Card(
                child: ListTile(
                  onTap: onFavoritesTap,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.red.shade400,
                    ),
                  ),
                  title: const Text(
                    'My Favorites',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('$favoritesCount favorite products'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),

              const SizedBox(height: 12),

              // ============================
              // MENU
              // ============================
              Card(
                child: Column(
                  children: [
                    ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrdersScreen(store: store),
                          ),
                        );
                      },
                      leading:
                          const Icon(Icons.receipt_long_outlined),
                      title: const Text(
                        'My Orders',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Track your orders'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SettingsScreen(),
                          ),
                        );
                      },
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text(
                        'Settings',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Preferences and more'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ============================
              // LOGOUT
              // ============================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ============================
              // DELETE ACCOUNT
              // ============================
              TextButton.icon(
                onPressed: onDeleteAccount,
                icon: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}