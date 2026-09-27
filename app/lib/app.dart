import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'features/capture/capture_screen.dart';
import 'features/diary/diary_screen.dart';
import 'features/review/review_screen.dart';
import 'infra/ai_client/parsed_meal_dto.dart';

/// Raíz de composición: es el único lugar que conoce las tres features y
/// las conecta por nombre de ruta (`app_routes.dart`). Las features nunca
/// se importan entre sí.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorías IA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: AppRoutes.diary,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.capture:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const CaptureScreen(),
            );
          case AppRoutes.review:
            final parsedMeal = settings.arguments as ParsedMealDto;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ReviewScreen(parsedMeal: parsedMeal),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const DiaryScreen(),
            );
        }
      },
    );
  }
}
