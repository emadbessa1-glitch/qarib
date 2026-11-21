import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../screens/place_details_screen.dart';
import '../utils/contact.dart';
import '../utils/geo.dart';
import 'rating_stars.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, this.userLocation});

  final Place place;
  final LatLng? userLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = userLocation == null
        ? null
        : formatDistance(metersBetween(userLocation!, place.location));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlaceDetailsScreen(place: place),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: place.category.color,
                foregroundColor: Colors.white,
                child: Icon(place.category.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      [place.area, if (distance != null) distance].join(' • '),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingStars(rating: place.rating, size: 14),
                        const SizedBox(width: 4),
                        Text('(${place.ratingCount})',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'اتصال',
                icon: const Icon(Icons.call),
                color: Colors.green.shade700,
                onPressed: () => callPhone(place.phone),
              ),
              if (place.hasWhatsapp)
                IconButton(
                  tooltip: 'واتساب',
                  icon: const Icon(Icons.chat),
                  color: const Color(0xFF25D366),
                  onPressed: () => openWhatsapp(place.whatsapp),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
