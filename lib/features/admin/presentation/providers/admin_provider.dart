import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_repository.dart';

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository());

final trainersProvider = StreamProvider<List<TrainerSummary>>(
  (ref) => ref.watch(adminRepositoryProvider).watchTrainers(),
);

final selfSignupProvider = StreamProvider<bool>(
  (ref) => ref.watch(adminRepositoryProvider).watchSelfSignup(),
);
