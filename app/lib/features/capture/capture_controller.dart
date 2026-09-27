import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ai_client/ai_client_errors.dart';
import '../../infra/ai_client/ai_client_providers.dart';
import '../../infra/ai_client/parsed_meal_dto.dart';

sealed class CaptureState {
  const CaptureState();
}

class CaptureIdle extends CaptureState {
  const CaptureIdle();
}

class CaptureLoading extends CaptureState {
  const CaptureLoading();
}

class CaptureSuccess extends CaptureState {
  final ParsedMealDto parsedMeal;

  const CaptureSuccess(this.parsedMeal);
}

class CaptureFailure extends CaptureState {
  final String message;

  const CaptureFailure(this.message);
}

/// R2: llama a `parseMeal` a través de `infra/ai_client`. El texto escrito
/// se conserva en la pantalla (la maneja `CaptureScreen`, no este
/// controller) para que un reintento no lo pierda.
class CaptureController extends Notifier<CaptureState> {
  @override
  CaptureState build() => const CaptureIdle();

  Future<void> analyze(String text) async {
    state = const CaptureLoading();
    try {
      final parsedMeal = await ref.read(aiClientProvider).parseMeal(text: text);
      state = CaptureSuccess(parsedMeal);
    } on AiClientException catch (error) {
      state = CaptureFailure(error.userMessage);
    }
  }

  void reset() => state = const CaptureIdle();
}

final captureControllerProvider =
    NotifierProvider<CaptureController, CaptureState>(CaptureController.new);
