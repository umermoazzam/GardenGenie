import 'package:flutter/material.dart';

void main() {
  runApp(const PlantShopApp());
}

class PlantShopApp extends StatelessWidget {
  const PlantShopApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const PlantShopHome(),
    );
  }
}

class PlantShopHome extends StatefulWidget {
  const PlantShopHome({Key? key}) : super(key: key);

  @override
  State<PlantShopHome> createState() => _PlantShopHomeState();
}

class _PlantShopHomeState extends State<PlantShopHome> {
  int _selectedCategoryIndex = 0;
  int _selectedNavIndex = 3;
  final TextEditingController _searchController = TextEditingController();
  
  // Filter states
  double _minPrice = 0;
  double _maxPrice = 100;
  bool _availableOnly = false;
  double _minRating = 0;
  List<String> _selectedCategories = [];

  final List<String> _categories = ['All', 'Indoor', 'Outdoor', 'Garden'];

  List<PlantItem> _allPlants = [
    PlantItem(
      name: 'Cactus envy',
      price: 65.00,
      image: 'cactus',
      backgroundColor: const Color(0xFFF5E6E8),
      category: 'Indoor',
      available: true,
      rating: 4.5,
    ),
    PlantItem(
      name: 'Dephrion',
      price: 65.00,
      image: 'dephrion',
      backgroundColor: const Color(0xFFE8F0E8),
      category: 'Indoor',
      available: true,
      rating: 4.8,
    ),
    PlantItem(
      name: 'White Lender',
      price: 65.00,
      image: 'white_lender',
      backgroundColor: const Color(0xFFFFFFFF),
      category: 'Indoor',
      available: true,
      rating: 4.2,
    ),
    PlantItem(
      name: 'Morning Be..',
      price: 65.00,
      image: 'morning_beauty',
      backgroundColor: const Color(0xFFE8F5E9),
      category: 'Indoor',
      available: true,
      rating: 4.6,
    ),
    PlantItem(
      name: 'Succulent Mix',
      price: 45.00,
      image: 'succulent',
      backgroundColor: const Color(0xFFFFF8E8),
      category: 'Outdoor',
      available: false,
      rating: 4.0,
    ),
    PlantItem(
      name: 'Pink Cactus',
      price: 75.00,
      image: 'pink_cactus',
      backgroundColor: const Color(0xFFF5F5F5),
      category: 'Indoor',
      available: true,
      rating: 4.9,
    ),
    PlantItem(
      name: 'Snake Plant',
      price: 55.00,
      image: 'snake_plant',
      backgroundColor: const Color(0xFFE8F0E8),
      category: 'Indoor',
      available: true,
      rating: 4.7,
    ),
    PlantItem(
      name: 'Monstera',
      price: 85.00,
      image: 'monstera',
      backgroundColor: const Color(0xFFF5F5F5),
      category: 'Indoor',
      available: true,
      rating: 4.8,
    ),
  ];

  List<PlantItem> get _filteredPlants {
    String query = _searchController.text.toLowerCase();
    String selectedCategory = _categories[_selectedCategoryIndex];
    
    return _allPlants.where((plant) {
      // Search filter
      bool matchesSearch = query.isEmpty || 
          plant.name.toLowerCase().contains(query);
      
      // Category filter
      bool matchesCategory = selectedCategory == 'All' || 
          plant.category == selectedCategory;
      
      // Price filter
      bool matchesPrice = plant.price >= _minPrice && plant.price <= _maxPrice;
      
      // Availability filter
      bool matchesAvailability = !_availableOnly || plant.available;
      
      // Rating filter
      bool matchesRating = plant.rating >= _minRating;
      
      // Selected categories filter (from filter dialog)
      bool matchesSelectedCategories = _selectedCategories.isEmpty || 
          _selectedCategories.contains(plant.category);
      
      return matchesSearch && matchesCategory && matchesPrice && 
             matchesAvailability && matchesRating && matchesSelectedCategories;
    }).toList();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Range
                        const Text(
                          'Price Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RangeSlider(
                          values: RangeValues(_minPrice, _maxPrice),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          activeColor: const Color(0xFF7CB342),
                          labels: RangeLabels(
                            '\$${_minPrice.toInt()}',
                            '\$${_maxPrice.toInt()}',
                          ),
                          onChanged: (values) {
                            setModalState(() {
                              _minPrice = values.start;
                              _maxPrice = values.end;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('\$${_minPrice.toInt()}'),
                            Text('\$${_maxPrice.toInt()}'),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Category Selection
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Indoor', 'Outdoor', 'Garden'].map((cat) {
                            bool isSelected = _selectedCategories.contains(cat);
                            return FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: const Color(0xFF7CB342).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF7CB342),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    _selectedCategories.add(cat);
                                  } else {
                                    _selectedCategories.remove(cat);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Availability
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Available Only',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Switch(
                              value: _availableOnly,
                              activeColor: const Color(0xFF7CB342),
                              onChanged: (value) {
                                setModalState(() {
                                  _availableOnly = value;
                                });
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Minimum Rating
                        const Text(
                          'Minimum Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _minRating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          activeColor: const Color(0xFF7CB342),
                          label: _minRating.toStringAsFixed(1),
                          onChanged: (value) {
                            setModalState(() {
                              _minRating = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('0.0'),
                            Text('${_minRating.toStringAsFixed(1)} ⭐'),
                            const Text('5.0'),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                
                // Apply Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _minPrice = 0;
                              _maxPrice = 100;
                              _availableOnly = false;
                              _minRating = 0;
                              _selectedCategories.clear();
                            });
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF7CB342)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Color(0xFF7CB342),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7CB342),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _selectedCategoryIndex == 0 ? 'Shop ' : 
                                _selectedCategoryIndex == 1 ? 'Indoor ' : 
                                _selectedCategoryIndex == 2 ? 'Outdoor ' : 'Garden ',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text: 'Plants',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7CB342),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar with Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.search,
                            color: Color(0xFFBDBDBD),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {});
                              },
                              decoration: const InputDecoration(
                                hintText: 'Search plants...',
                                hintStyle: TextStyle(
                                  color: Color(0xFFBDBDBD),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showFilterDialog,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7CB342),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: List.generate(_categories.length, (index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7CB342)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _categories[index],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF9E9E9E),
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Results count
            if (_searchController.text.isNotEmpty || _minPrice > 0 || 
                _maxPrice < 100 || _availableOnly || _minRating > 0 ||
                _selectedCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${_filteredPlants.length} results found',
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // Plant Grid
            Expanded(
              child: _filteredPlants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No plants found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _filteredPlants.length,
                        itemBuilder: (context, index) {
                          return PlantCard(plant: _filteredPlants[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF7CB342),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7CB342).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 0),
              _buildNavItem(Icons.map_outlined, 1),
              const SizedBox(width: 40),
              _buildNavItem(Icons.person_outline, 2),
              _buildNavItem(Icons.grid_view_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      child: Icon(
        icon,
        color: isSelected ? const Color(0xFF7CB342) : const Color(0xFFBDBDBD),
        size: 26,
      ),
    );
  }
}

class PlantCard extends StatelessWidget {
  final PlantItem plant;

  const PlantCard({Key? key, required this.plant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: plant.backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: _getPlantImage(plant.image),
                  ),
                ),
                if (!plant.available)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${plant.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7CB342),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFFFA000),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          plant.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPlantImage(String imageName) {
    final imageMap = {
      'cactus': 'https://images.unsplash.com/photo-1509587584298-0f3b3a3a1797?w=300&h=300&fit=crop',
      'dephrion': 'https://images.unsplash.com/photo-1597199479244-8db1fde4c7a6?w=300&h=300&fit=crop',
      'white_lender': 'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=300&h=300&fit=crop',
      'morning_beauty': 'https://images.unsplash.com/photo-1551811305-c76906c7e0a4?w=300&h=300&fit=crop',
      'succulent': 'https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=300&h=300&fit=crop',
      'pink_cactus': 'https://images.unsplash.com/photo-1615811361523-6bd03d7748e7?w=300&h=300&fit=crop',
      'snake_plant': 'https://images.unsplash.com/photo-1593691509543-c55fb32d8de5?w=300&h=300&fit=crop',
      'monstera': 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=300&h=300&fit=crop',
    };

    return Image.network(
      imageMap[imageName] ?? imageMap['cactus']!,
      width: 120,
      height: 120,
      fit: BoxFit.contain,
    );
  }
}

class PlantItem {
  final String name;
  final double price;
  final String image;
  final Color backgroundColor;
  final String category;
  final bool available;
  final double rating;

  PlantItem({
    required this.name,
    required this.price,
    required this.image,
    required this.backgroundColor,
    required this.category,
    required this.available,
    required this.rating,
  });
}