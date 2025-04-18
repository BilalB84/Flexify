import 'package:drift/drift.dart' as drift;
import 'package:flexify/constants.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/plan/edit_plan_page.dart';
import 'package:flexify/plan/plan_state.dart';
import 'package:flexify/plan/plan_tile.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlansList extends StatelessWidget {
  final List<Plan> plans;
  final GlobalKey<NavigatorState> navigatorKey;
  final Set<int> selected;
  final Function(int) onSelect;
  final String search;

  const PlansList({
    super.key,
    required this.plans,
    required this.navigatorKey,
    required this.selected,
    required this.onSelect,
    required this.search,
  });

  @override
  Widget build(BuildContext context) {
    final weekday = weekdays[DateTime.now().weekday - 1];
    final planState = context.watch<PlanState>();

    if (plans.isEmpty)
      return ListTile(
        title: const Text("No plans found"),
        subtitle: Text("Tap to create $search"),
        onTap: () async {
          final plan = PlansCompanion(
            days: const drift.Value(''),
            exercises: const drift.Value(''),
            title: drift.Value(search),
          );
          await planState.setExercises(plan);
          if (context.mounted)
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPlanPage(
                  plan: plan,
                ),
              ),
            );
        },
      );

    final settings = context.read<SettingsState>();

    if (settings.value.planTrailing == PlanTrailing.reorder.toString())
      return ReorderableListView.builder(
        itemCount: plans.length,
        padding: const EdgeInsets.only(bottom: 50, top: 8),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return PlanTile(
            key: Key(plan.id.toString()),
            plan: plan,
            weekday: weekday,
            index: index,
            navigatorKey: navigatorKey,
            selected: selected,
            onSelect: (id) => onSelect(id),
          );
        },
        onReorder: (int oldIndex, int newIndex) async {
          if (oldIndex < newIndex) {
            newIndex--;
          }

          final temp = plans[oldIndex];
          plans.removeAt(oldIndex);
          plans.insert(newIndex, temp);

          final planState = context.read<PlanState>();
          planState.updatePlans(plans);
          await db.transaction(() async {
            for (int i = 0; i < plans.length; i++) {
              final plan = plans[i];
              final updatedPlan =
                  plan.toCompanion(false).copyWith(sequence: drift.Value(i));
              await db.update(db.plans).replace(updatedPlan);
            }
          });
        },
      );

    return ListView.builder(
      itemCount: plans.length,
      padding: const EdgeInsets.only(bottom: 50),
      itemBuilder: (context, index) {
        final plan = plans[index];

        return PlanTile(
          plan: plan,
          weekday: weekday,
          index: index,
          navigatorKey: navigatorKey,
          selected: selected,
          onSelect: (id) => onSelect(id),
        );
      },
    );
  }
}
