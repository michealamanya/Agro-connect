import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/produce_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/produce_service.dart';
import '../../utils/app_theme.dart';
import '../produce/produce_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _selectedFilter = 'All'; // All, Ready, Unready
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final produceService = context.read<ProduceService>();
    final user = authService.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroConnect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search produce...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedFilter == 'All',
                  onTap: () => setState(() => _selectedFilter = 'All'),
                ),
                _FilterChip(
                  label: 'Ready',
                  isSelected: _selectedFilter == 'Ready',
                  color: AppTheme.readyColor,
                  onTap: () => setState(() => _selectedFilter = 'Ready'),
                ),
                _FilterChip(
                  label: 'Unready',
                  isSelected: _selectedFilter == 'Unready',
                  color: AppTheme.unreadyColor,
                  onTap: () => setState(() => _selectedFilter = 'Unready'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedCategory == 'All',
                  onTap: () => setState(() => _selectedCategory = 'All'),
                ),
                ...ProduceService.categories.map((cat) => _FilterChip(
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Produce list
          Expanded(
            child: StreamBuilder<List<ProduceModel>>(
              stream: _searchQuery.isNotEmpty
                  ? produceService.searchProduce(_searchQuery)
                  : produceService.getAllProduceStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                var produceList = snapshot.data ?? [];

                // Apply filters
                if (_selectedFilter == 'Ready') {
                  produceList = produceList
                      .where((p) => p.status == ProduceStatus.ready)
                      .toList();
                } else if (_selectedFilter == 'Unready') {
                  produceList = produceList
                      .where((p) => p.status == ProduceStatus.unready)
                      .toList();
                }

                if (_selectedCategory != 'All') {
                  produceList = produceList
                      .where((p) => p.category == _selectedCategory)
                      .toList();
                }

                if (produceList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No produce found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: produceList.length,
                  itemBuilder: (context, index) {
                    final produce = produceList[index];
                    return _ProduceCard(produce: produce);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: user?.role == UserRole.farmer
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/add-produce'),
              icon: const Icon(Icons.add),
              label: const Text('Add Produce'),
            )
          : null,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryGreen;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProduceCard extends StatelessWidget {
  final ProduceModel produce;

  const _ProduceCard({required this.produce});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProduceDetailScreen(produce: produce),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: produce.imageUrls.isNotEmpty
                  ? Image.network(
                      produce.imageUrls.first,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 50),
                      ),
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.eco, size: 50, color: Colors.grey),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge & category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: produce.isReady
                              ? AppTheme.readyColor
                              : AppTheme.unreadyColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          produce.isReady ? 'Ready' : 'Unready',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          produce.category,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Name
                  Text(
                    produce.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Text(
                    'KSh ${produce.price.toStringAsFixed(2)} / ${produce.unit}',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Farmer & Location
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        produce.farmerName,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (produce.location != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            produce.location!,
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
