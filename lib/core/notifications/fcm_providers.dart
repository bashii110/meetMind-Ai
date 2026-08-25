import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import 'fcm_service.dart';

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(ref.watch(dioProvider)));
