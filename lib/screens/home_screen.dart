import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';

import '../models/category.dart';
import '../services/location_service.dart';
import '../services/profile_service.dart';
import '../services/update_service.dart';
import '../utils/geo.dart';
import '../widgets/approved_places_builder.dart';
import '../widgets/place_card.dart';
import 'add_place_screen.dart';
import 'account_screen.dart';
import 'admin_screen.dart';
import 'chat_screen.dart';
import 'legal_screen.dart';
import 'map_screen.dart';
import 'my_places_screen.dart';
import 'places_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openList(BuildContext context,
      {PlaceCategory? category, String query = ''}) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          PlacesListScreen(initialCategory: category, initialQuery: query),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationService>();
    final profile = context.watch<ProfileService>();
    final isBusiness = profile.isBusiness;
    final hasUpdate = context.watch<UpdateService>().hasUpdate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('قريب'),
        actions: [
          IconButton(
            tooltip: 'المحادثات',
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const InboxScreen()),
            ),
          ),
          if (isBusiness)
            IconButton(
              tooltip: 'أماكني',
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MyPlacesScreen()),
              ),
            ),
          IconButton(
            tooltip: 'الخريطة',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MapScreen()),
            ),
          ),
          PopupMenuButton<Widget>(
            tooltip: 'المزيد',
            onSelected: (screen) => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => screen),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: AccountScreen(),
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('حسابي'),
                ),
              ),
              PopupMenuItem(
                value: LegalScreen.privacy(),
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('سياسة الخصوصية'),
                ),
              ),
              PopupMenuItem(
                value: AdminScreen(),
                child: ListTile(
                  leading: Icon(Icons.admin_panel_settings_outlined),
                  title: Text('لوحة الإدارة'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: isBusiness
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddPlaceScreen()),
              ),
              icon: const Icon(Icons.add_business),
              label: const Text('أضف مكانك'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: location.refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            if (hasUpdate) const _UpdateBanner(),
            if (profile.name.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'أهلاً ${profile.name} 👋',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'دوّر على صيدلية، دكتور، سنتر...',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (q) => _openList(context, query: q.trim()),
              ),
            ),
            _LocationBanner(location: location),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final c in PlaceCategory.values)
                    _CategoryTile(
                      category: c,
                      onTap: () => _openList(context, category: c),
                    ),
                  _AllTile(onTap: () => _openList(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(
                location.position == null ? 'الأعلى تقييماً' : 'الأقرب ليك',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ApprovedPlacesBuilder(
              builder: (context, all) {
                final places =
                    sortPlaces(all, location.position).take(5).toList();
                if (places.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('لسه مفيش أماكن متسجلة'),
                  );
                }
                return Column(
                  children: [
                    for (final p in places)
                      PlaceCard(place: p, userLocation: location.position),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.location});

  final LocationService location;

  @override
  Widget build(BuildContext context) {
    if (location.loading) {
      return const ListTile(
        dense: true,
        leading: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('بنحدد موقعك...'),
      );
    }
    if (location.position != null) return const SizedBox(height: 8);
    return ListTile(
      dense: true,
      leading: const Icon(Icons.location_off_outlined),
      title: Text(location.error ?? 'الموقع مش متحدد'),
      subtitle: const Text('فعّل الموقع عشان نرتبلك الأماكن بالأقرب'),
      trailing: TextButton(
        onPressed: location.refresh,
        child: const Text('حاول تاني'),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final PlaceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, size: 36, color: category.color),
            const SizedBox(height: 8),
            Text(category.label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AllTile extends StatelessWidget {
  const _AllTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps, size: 36),
            SizedBox(height: 8),
            Text('كل الخدمات'),
          ],
        ),
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: scheme.tertiaryContainer,
      child: ListTile(
        leading: const Icon(Icons.system_update),
        title: const Text('فيه تحديث جديد للتطبيق'),
        subtitle: const Text('نزّل آخر نسخة عشان تاخد آخر المميزات'),
        trailing: FilledButton(
          onPressed: () => launchUrl(
            Uri.parse(AppConfig.latestApkUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: const Text('تحديث'),
        ),
      ),
    );
  }
}
