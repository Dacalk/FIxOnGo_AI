import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Data model for a tool/part available for delivery.
class ToolItem {
  final String name;
  final String subtitle;
  final String price;
  final String eta;
  final String category;
  final IconData placeholderIcon;
  final bool isUrgent;

  const ToolItem({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.eta,
    required this.category,
    required this.placeholderIcon,
    this.isUrgent = false,
  });
}

/// Request Tools screen — browse and order tools/parts for delivery.
/// Accessed from the User dashboard "Get Tools" button.
class RequestToolsScreen extends StatefulWidget {
  const RequestToolsScreen({super.key});

  @override
  State<RequestToolsScreen> createState() => _RequestToolsScreenState();
}

class _RequestToolsScreenState extends State<RequestToolsScreen> {
  String _selectedCategory = 'All';
  final Set<int> _addedItems = {0}; // Battery pre-selected
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = ['All', 'Tires', 'Battery', 'Fuel'];
  static const List<IconData> _categoryIcons = [
    Icons.abc, // placeholder, not shown for "All"
    Icons.tire_repair,
    Icons.bolt,
    Icons.local_gas_station,
  ];

  static const List<ToolItem> _items = [
    ToolItem(
      name: 'Battery',
      subtitle: '12ft, 4 Gauge - Universal',
      price: 'Rs. 5000',
      eta: '15m',
      category: 'Battery',
      placeholderIcon: Icons.battery_charging_full,
    ),
    ToolItem(
      name: 'Emergency Fuel (5L)',
      subtitle: 'Unleaded 95 - Jerry Can',
      price: 'Rs. 2,500',
      eta: '10m',
      category: 'Fuel',
      placeholderIcon: Icons.local_gas_station,
      isUrgent: true,
    ),
    ToolItem(
      name: 'Universal Tire Jack',
      subtitle: '2 Ton Scissor Jack',
      price: 'Rs. 8,500',
      eta: '25m',
      category: 'Tires',
      placeholderIcon: Icons.tire_repair,
    ),
    ToolItem(
      name: 'Coolant / Antifreeze',
      subtitle: 'Premixed, All Makes',
      price: 'Rs. 3,200',
      eta: '20m',
      category: 'Battery',
      placeholderIcon: Icons.local_drink,
    ),
  ];

  List<ToolItem> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    return _items.where((i) => i.category == _selectedCategory).toList();
  }

  int get _selectedCount => _addedItems.length;

  int get _totalPrice {
    int total = 0;
    for (final i in _addedItems) {
      final raw = _items[i].price.replaceAll('Rs. ', '').replaceAll(',', '');
      total += int.tryParse(raw) ?? 0;
    }
    return total;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[500]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;
    final searchBg = dark ? AppColors.darkSurface : const Color(0xFFF1F6FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Request Tools',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: dark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: dark ? Colors.white : AppColors.primaryBlue,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),

                // ── Search Bar ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: searchBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: titleColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search for tools, parts...',
                      hintStyle: TextStyle(
                        color: dark ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: Icon(
                        Icons.mic,
                        color: dark ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Category Filter Chips ──
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (context, i) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : (dark
                                      ? AppColors.darkSurface
                                      : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : borderColor,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index > 0) ...[
                                Icon(
                                  _categoryIcons[index],
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : (dark
                                            ? Colors.grey[400]
                                            : Colors.grey[600]),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (dark
                                            ? Colors.grey[300]
                                            : Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ── Available in Location Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available in Badulla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'View map',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Item List ──
                ..._filteredItems.map((item) {
                  final globalIndex = _items.indexOf(item);
                  return _buildToolCard(
                    item,
                    globalIndex,
                    dark,
                    cardBg,
                    borderColor,
                    titleColor,
                    subColor,
                  );
                }),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Bottom Cart Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_selectedCount items selected',
                              style: TextStyle(fontSize: 12, color: subColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${_formatNumber(_totalPrice)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _selectedCount > 0
                            ? () {
                                // Request delivery action
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dark
                              ? AppColors.brandYellow
                              : AppColors.primaryBlue,
                          foregroundColor: dark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Request Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── AI Assistant CTA ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        // AI avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF1E3350)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.smart_toy,
                            size: 22,
                            color: dark ? Colors.tealAccent : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Not sure what you need?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Our AI assistant can analyze your car\'s issue and suggest the right tools.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/ai-chat');
                                },
                                child: Text(
                                  'Ask AI Assistant →',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single tool/part card with Add / Added button.
  Widget _buildToolCard(
    ToolItem item,
    int index,
    bool dark,
    Color cardBg,
    Color borderColor,
    Color titleColor,
    Color subColor,
  ) {
    final isAdded = _addedItems.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Product image placeholder
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: dark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.placeholderIcon,
                  color: dark ? Colors.white54 : Colors.grey[500],
                  size: 34,
                ),
              ),
              if (item.isUrgent)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                const SizedBox(height: 6),
                Text(
                  item.price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ETA: ${item.eta}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Add / Added button
          GestureDetector(
            onTap: () {
              setState(() {
                if (isAdded) {
                  _addedItems.remove(index);
                } else {
                  _addedItems.add(index);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isAdded
                    ? Colors.transparent
                    : (dark ? AppColors.brandYellow : AppColors.primaryBlue),
                borderRadius: BorderRadius.circular(10),
                border: isAdded
                    ? Border.all(
                        color: dark ? Colors.grey[600]! : Colors.grey[400]!,
                      )
                    : null,
              ),
              child: Text(
                isAdded ? 'Added' : 'Add',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isAdded
                      ? subColor
                      : (dark ? Colors.black : Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n == 0) return '0';
    final str = n.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) buffer.write(',');
    }
    return buffer.toString().split('').reversed.join();
  }
}
