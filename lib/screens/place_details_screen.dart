import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../data/chat_repository.dart';
import '../data/places_repository.dart';
import '../data/reports_repository.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/profile_service.dart';
import '../utils/contact.dart';
import '../utils/geo.dart';
import '../widgets/approved_places_builder.dart';
import '../widgets/osm_map.dart';
import '../widgets/rating_stars.dart';
import '../widgets/report_dialog.dart';
import 'add_place_screen.dart';
import 'chat_screen.dart';

class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({super.key, required this.place});

  final Place place;

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  late final Stream<List<Review>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = context.read<PlacesRepository>().watchReviews(widget.place.id);
  }

  Future<void> _addReview() async {
    final result = await showDialog<_ReviewInput>(
      context: context,
      builder: (_) => _ReviewDialog(
        initialName: context.read<ProfileService>().name,
      ),
    );
    if (result == null || !mounted) return;

    final repo = context.read<PlacesRepository>();
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.ensureSignedIn();
      await repo.addReview(Review(
        id: '',
        placeId: widget.place.id,
        authorName: result.name,
        rating: result.rating,
        comment: result.comment,
        createdAt: DateTime.now(),
        authorId: auth.userId,
      ));
      messenger.showSnackBar(
        const SnackBar(content: Text('شكراً! تقييمك اتسجل')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('معرفناش نسجل التقييم، حاول تاني')),
      );
    }
  }

  Future<void> _openChat(Place place) async {
    final auth = context.read<AuthService>();
    final chats = context.read<ChatRepository>();
    final name = context.read<ProfileService>().name;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.ensureSignedIn();
      final chatId = await chats.openChat(
        place: place,
        userId: auth.userId!,
        userName: name.isEmpty ? 'عميل' : name,
      );
      nav.push(MaterialPageRoute<void>(
        builder: (_) => ChatScreen(chatId: chatId, title: place.name),
      ));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('معرفناش نفتح المحادثة، حاول تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LocationService>().position;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
        actions: [
          if (context.watch<AuthService>().isStaff)
            IconButton(
              tooltip: 'تعديل بيانات المكان',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AddPlaceScreen(editing: widget.place),
                ),
              ),
            ),
          IconButton(
            tooltip: 'إبلاغ عن المكان',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => showReportDialog(
              context,
              target: ReportTarget.place,
              placeId: widget.place.id,
              reportedUserId: widget.place.ownerId ?? '',
              excerpt: widget.place.name,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReview,
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('قيّم المكان'),
      ),
      // بنسمع للقائمة عشان التقييم يتحدث أول ما حد يضيف تقييم.
      body: ApprovedPlacesBuilder(
        builder: (context, all) {
          final place = all.firstWhere(
            (p) => p.id == widget.place.id,
            orElse: () => widget.place,
          );
          return _buildBody(context, place, user);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, Place place, LatLng? user) {
    final theme = Theme.of(context);
    final myId = context.watch<AuthService>().userId;
    final canChat = !place.hasWhatsapp &&
        (place.ownerId ?? '').isNotEmpty &&
        place.ownerId != myId;
    final distance = user == null
        ? null
        : formatDistance(metersBetween(user, place.location));

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: place.category.color,
            foregroundColor: Colors.white,
            child: Icon(place.category.icon),
          ),
          title: Text(place.name, style: theme.textTheme.titleLarge),
          subtitle: Text(
            [place.category.label, place.locationLabel, if (distance != null) distance]
                .join(' • '),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              RatingStars(rating: place.rating, size: 22),
              const SizedBox(width: 8),
              Text(
                place.ratingCount == 0
                    ? 'لسه مفيش تقييمات'
                    : '${place.rating.toStringAsFixed(1)} من 5 (${place.ratingCount} تقييم)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => callPhone(place.phone),
                  icon: const Icon(Icons.call),
                  label: const Text('اتصال'),
                ),
              ),
              if (canChat) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openChat(place),
                    icon: const Icon(Icons.forum),
                    label: const Text('راسلهم'),
                  ),
                ),
              ],
              if (place.hasWhatsapp) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                    ),
                    onPressed: () => openWhatsapp(
                      place.whatsapp,
                      message: 'السلام عليكم، وصلتلكم من تطبيق قريب',
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text('واتساب'),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openDirections(place),
                  icon: const Icon(Icons.directions),
                  label: const Text('الاتجاهات'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (place.address.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(place.address),
          ),
        ListTile(
          leading: const Icon(Icons.phone_outlined),
          title: Text(place.phone, textDirection: TextDirection.ltr),
        ),
        if (place.workingHours.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(place.workingHours),
          ),
        if (place.description.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(place.description),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: place.location,
                  initialZoom: 15,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  ...osmBaseLayers(),
                  MarkerLayer(markers: [
                    Marker(
                      point: place.location,
                      width: 44,
                      height: 44,
                      child: Icon(Icons.location_on,
                          size: 44, color: place.category.color),
                    ),
                  ]),
                  osmAttribution(),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text('التقييمات', style: theme.textTheme.titleMedium),
        ),
        StreamBuilder<List<Review>>(
          stream: _reviews,
          builder: (context, snap) {
            final reviews = snap.data ?? const <Review>[];
            if (snap.connectionState == ConnectionState.waiting &&
                reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('كن أول واحد يقيّم المكان ده'),
              );
            }
            return Column(
              children: [
                for (final r in reviews)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Row(
                      children: [
                        Flexible(child: Text(r.authorName)),
                        const SizedBox(width: 8),
                        RatingStars(rating: r.rating.toDouble(), size: 14),
                      ],
                    ),
                    subtitle: r.comment.isEmpty ? null : Text(r.comment),
                    trailing: r.authorId != null &&
                            r.authorId == context.read<AuthService>().userId
                        ? null
                        : IconButton(
                            tooltip: 'إبلاغ',
                            icon: const Icon(Icons.flag_outlined, size: 20),
                            onPressed: () => showReportDialog(
                              context,
                              target: ReportTarget.review,
                              placeId: widget.place.id,
                              itemId: r.id,
                              reportedUserId: r.authorId ?? '',
                              excerpt: '${r.authorName}: ${r.comment}',
                            ),
                          ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewInput {
  const _ReviewInput(this.name, this.rating, this.comment);
  final String name;
  final int rating;
  final String comment;
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({this.initialName = ''});

  final String initialName;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  final _comment = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _name.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('قيّم المكان'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingPicker(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسمك'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'رأيك (اختياري)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _rating == 0
              ? null
              : () => Navigator.of(context).pop(_ReviewInput(
                    _name.text.trim().isEmpty ? 'زائر' : _name.text.trim(),
                    _rating,
                    _comment.text.trim(),
                  )),
          child: const Text('إرسال'),
        ),
      ],
    );
  }
}
