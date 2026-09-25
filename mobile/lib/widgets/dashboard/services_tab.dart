import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/catalog_providers.dart';
import '../../screens/department_services_screen.dart';
import '../category_card.dart';

class ServicesTab extends ConsumerWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Departments'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: departments.isLoading && !departments.hasValue
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.refresh(servicesProvider.future),
              child: _buildGrid(
                context,
                departments.value ?? const {},
                departments.hasError ? 'Could not load services. Pull down to retry.' : null,
              ),
            ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    Map<String, List<Map<String, dynamic>>> departments,
    String? error,
  ) {
    if (departments.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text(error ?? 'No services found in database.')),
        ],
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemCount: departments.length,
      itemBuilder: (context, index) {
        final name = departments.keys.elementAt(index);
        final services = departments[name]!;
        return CategoryCard(
          title: '$name\n${services.length} service${services.length == 1 ? '' : 's'}',
          icon: departmentIcon(name),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => DepartmentServicesScreen(
                  department: name,
                  services: services,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Best-effort icon for a department name; falls back to a generic building.
IconData departmentIcon(String department) {
  final d = department.toLowerCase();
  if (d.contains('health') || d.contains('medical')) return CupertinoIcons.heart;
  if (d.contains('educat') || d.contains('school')) return CupertinoIcons.book;
  if (d.contains('transport') || d.contains('motor') || d.contains('vehicle') || d.contains('licen')) {
    return CupertinoIcons.car_detailed;
  }
  if (d.contains('immigra') || d.contains('passport') || d.contains('travel')) return CupertinoIcons.airplane;
  if (d.contains('registr') || d.contains('identity') || d.contains('civil') || d.contains('birth')) {
    return CupertinoIcons.person_crop_rectangle;
  }
  if (d.contains('land') || d.contains('property') || d.contains('housing')) return CupertinoIcons.house;
  if (d.contains('tax') || d.contains('revenue') || d.contains('finance')) return CupertinoIcons.money_dollar_circle;
  if (d.contains('police') || d.contains('legal') || d.contains('justice')) return CupertinoIcons.shield;
  if (d.contains('business') || d.contains('trade') || d.contains('commerce')) return CupertinoIcons.briefcase;
  if (d.contains('welfare') || d.contains('social')) return CupertinoIcons.person_3;
  return CupertinoIcons.building_2_fill;
}
