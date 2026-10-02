import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyActivityState {
  final int steps;
  final int stepGoal;
  final double caloriesBurned;

  const DailyActivityState({
    this.steps = 0,
    this.stepGoal = 8000,
    this.caloriesBurned = 0.0,
  });

  double get progress => (steps / stepGoal).clamp(0.0, 1.0);
}

class StepTrackerNotifier extends StateNotifier<DailyActivityState> {
  StepTrackerNotifier() : super(const DailyActivityState(steps: 5420, caloriesBurned: 210.5));

  // Gerçek pedometer paketi bağlandığında burası donanımdan gelen stream'i dinler
  void updateSteps(int newSteps) {
    state = DailyActivityState(
      steps: newSteps,
      caloriesBurned: newSteps * 0.04,
    );
  }
}

final stepTrackerProvider = StateNotifierProvider<StepTrackerNotifier, DailyActivityState>((ref) {
  return StepTrackerNotifier();
});