import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_licenses.dart';
import 'app/lee_con_leo_app.dart';
import 'core/profiles/profile_providers.dart';
import 'core/storage/app_database.dart';
import 'core/storage/drift_profile_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppLicenses.register(rootBundle);
  final container = ProviderContainer(
    overrides: [
      if (!kIsWeb)
        profileStoreProvider.overrideWithValue(
          DriftProfileStore(AppDatabase(driftDatabase(name: 'lee_con_leo'))),
        ),
    ],
  );
  runApp(UncontrolledProviderScope(container: container, child: const LeeConLeoApp()));
}
