import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/places_repository.dart';
import '../models/place.dart';

/// بيسمع لقائمة الأماكن المتوافق عليها مرة واحدة (من غير ما يعيد الاشتراك مع كل rebuild)
/// وبيعرض تحميل/خطأ بشكل موحد.
class ApprovedPlacesBuilder extends StatefulWidget {
  const ApprovedPlacesBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, List<Place> places) builder;

  @override
  State<ApprovedPlacesBuilder> createState() => _ApprovedPlacesBuilderState();
}

class _ApprovedPlacesBuilderState extends State<ApprovedPlacesBuilder> {
  late final Stream<List<Place>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<PlacesRepository>().watchApproved();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Place>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('حصلت مشكلة في تحميل البيانات'),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return widget.builder(context, snap.data!);
      },
    );
  }
}
