import '../models/habit_model.dart';

abstract class HabitRepository {
  Future<List<HabitModel>> getHabits();
  Future<void> addHabit(HabitModel habit);
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(String id);
}
