import 'dart:developer' as developer;

import '../../data/remote/supabase_client.dart';

class AppMonitoring {
  const AppMonitoring._();

  static Future<void> logQueryFailure({
    required String source,
    required String event,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    final fallbackMessage = '[monitoring][$source][$event] ${error.toString()}';

    final client = SupabaseClientRef.maybeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      developer.log(
        fallbackMessage,
        name: 'med_syn.monitoring',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    try {
      await client.rpc(
        'log_client_monitoring_event',
        params: {
          'source_name': source,
          'event_name': event,
          'message_text': error.toString(),
          'metadata': {
            'user_id': user.id,
            'error_type': error.runtimeType.toString(),
            ...?metadata,
          },
        },
      );
    } catch (rpcError, rpcStack) {
      developer.log(
        '$fallbackMessage | rpc_error=${rpcError.toString()}',
        name: 'med_syn.monitoring',
        error: rpcError,
        stackTrace: rpcStack,
      );
    }
  }
}
