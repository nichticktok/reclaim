import os
import re

# Mapping of old file patterns (partial paths) to new package imports
replacements = {
    r"['\"].*models/achievement_model\.dart['\"]": "'package:recalim/features/achievements/domain/entities/achievement_model.dart'",
    r"['\"].*models/community_comment_model\.dart['\"]": "'package:recalim/features/community/domain/entities/community_comment_model.dart'",
    r"['\"].*models/community_post_model\.dart['\"]": "'package:recalim/features/community/domain/entities/community_post_model.dart'",
    r"['\"].*models/habit_model\.dart['\"]": "'package:recalim/features/tasks/domain/entities/habit_model.dart'",
    r"['\"].*models/milestone_model\.dart['\"]": "'package:recalim/features/milestone/domain/entities/milestone_model.dart'",
    r"['\"].*models/preset_task_model\.dart['\"]": "'package:recalim/features/tasks/domain/entities/preset_task_model.dart'",
    r"['\"].*models/progress_model\.dart['\"]": "'package:recalim/features/progress/domain/entities/progress_model.dart'",
    r"['\"].*models/project_model\.dart['\"]": "'package:recalim/features/projects/domain/entities/project_model.dart'",
    r"['\"].*models/user_model\.dart['\"]": "'package:recalim/core/models/user_model.dart'",
    r"['\"].*models/user_stats_model\.dart['\"]": "'package:recalim/core/models/user_stats_model.dart'",
    r"['\"].*models/workout_model\.dart['\"]": "'package:recalim/features/workouts/domain/entities/workout_model.dart'",
    
    r"['\"].*providers/language_provider\.dart['\"]": "'package:recalim/core/providers/language_provider.dart'",
    r"['\"].*providers/language_helper\.dart['\"]": "'package:recalim/core/providers/language_helper.dart'",
    
    r"['\"].*widgets/custom_button\.dart['\"]": "'package:recalim/core/widgets/custom_button.dart'",
    r"['\"].*widgets/progress_ring\.dart['\"]": "'package:recalim/core/widgets/progress_ring.dart'",
    r"['\"].*widgets/habit_card\.dart['\"]": "'package:recalim/features/tasks/presentation/widgets/habit_card.dart'",
    r"['\"].*widgets/proof_input_box\.dart['\"]": "'package:recalim/features/tasks/presentation/widgets/proof_input_box.dart'",
    r"['\"].*widgets/reflection_card\.dart['\"]": "'package:recalim/features/reflection/presentation/widgets/reflection_card.dart'",
    
    r"['\"].*routes/app_routes\.dart['\"]": "'package:recalim/core/routes/app_routes.dart'",
}

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        for pattern, replacement in replacements.items():
            # Use regex to replace import statements
            # Look for import ... pattern ... ;
            # We match the string part of the import
            content = re.sub(pattern, replacement, content)
            
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated: {filepath}")
            
    except Exception as e:
        print(f"Error processing {filepath}: {e}")

def main():
    root_dir = 'lib'
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
