import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/profiles/profile_providers.dart';

final greetingProvider = NotifierProvider<Greeting, bool>(Greeting.new);

final finishCheerProvider = NotifierProvider<Greeting, bool>(Greeting.new);

class Greeting extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(activeProfileProvider);
    return false;
  }

  bool takeTurn() {
    if (state) return false;
    state = true;
    return true;
  }
}
