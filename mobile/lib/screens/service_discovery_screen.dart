import 'package:flutter/material.dart';
import '../services/service_api_client.dart';
import 'procedure_detail_screen.dart';

class ServiceDiscoveryScreen extends StatefulWidget {
  final String initialCategory;
  const ServiceDiscoveryScreen({super.key, this.initialCategory = 'All'});

  @override
  State<ServiceDiscoveryScreen> createState() => _ServiceDiscoveryScreenState();
}

class _ServiceDiscoveryScreenState extends State<ServiceDiscoveryScreen> {
  List services = [];
  List filteredServices = [];
  bool isLoading = true;
  String searchQuery = '';
  late String selectedCategory;

  final List<String> categories = ['All', 'Commerce', 'Transport', 'Identity', 'Housing', 'Taxes'];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    loadServices();
  }

  void loadServices() async {
    try {
      final data = await ServiceApiClient.fetchServices();
      setState(() {
        services = data;
        applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void filterSearch(String query) {
    setState(() {
      searchQuery = query;
      applyFilters();
    });
  }

  void filterCategory(String category) {
    setState(() {
      selectedCategory = category;
      applyFilters();
    });
  }

  void applyFilters() {
    filteredServices = services.where((service) {
      final serviceName = service['name']?.toLowerCase() ?? '';
      final serviceId = service['serviceId']?.toLowerCase() ?? '';
      final serviceCategory = service['category'] ?? '';

      final matchesSearch = serviceName.contains(searchQuery.toLowerCase()) ||
                            serviceId.contains(searchQuery.toLowerCase());
      
      final matchesCategory = selectedCategory == 'All' || 
                            serviceCategory.toLowerCase() == selectedCategory.toLowerCase();
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(selectedCategory == 'All' ? 'Government Services' : '$selectedCategory Services')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: filterSearch,
              decoration: const InputDecoration(
                labelText: 'Search procedures...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    onSelected: (selected) => filterCategory(cat),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredServices.isEmpty
                    ? const Center(child: Text('No services found in this category.'))
                    : ListView.builder(
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          final fees = service['feeSchedules'] as List? ?? [];
                          final feeString = fees.isNotEmpty ? 'LKR ${fees[0]['amount']}' : 'Free';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(service['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Category: ${service['category']} | Fee: $feeString'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProcedureDetailScreen(serviceId: service['id']),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
