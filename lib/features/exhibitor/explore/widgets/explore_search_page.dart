import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';

class ExploreSearchPage extends StatefulWidget {
  final String initialQuery;
  final String initialFilter;

  const ExploreSearchPage({
    super.key,
    required this.initialQuery,
    required this.initialFilter,
  });

  @override
  State<ExploreSearchPage> createState() => _ExploreSearchPageState();
}

class _ExploreSearchPageState extends State<ExploreSearchPage> {
  late final TextEditingController _controller;
  late String _selectedFilter;

  final List<Map<String, dynamic>> _suggestions = const [
    {
      'title': 'Food',
      'subtitle': 'Browse food exhibitions',
      'query': 'Food',
      'icon': Icons.restaurant,
    },
    {
      'title': 'Technology',
      'subtitle': 'Innovations & gadgets',
      'query': 'Technology',
      'icon': Icons.devices_other_rounded,
    },
    {
      'title': 'Kuala Lumpur',
      'subtitle': 'Events around Kuala Lumpur',
      'query': 'Kuala Lumpur',
      'icon': Icons.location_on_rounded,
    },
    {
      'title': 'Cyberjaya',
      'subtitle': 'Events around Cyberjaya',
      'query': 'Cyberjaya',
      'icon': Icons.location_on_rounded,
    },
    {
      'title': 'Indoor',
      'subtitle': 'Indoor events',
      'query': 'Indoor',
      'icon': Icons.home_rounded,
    },
    {
      'title': 'Outdoor',
      'subtitle': 'Outdoor events',
      'query': 'Outdoor',
      'icon': Icons.wb_sunny_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _selectedFilter = widget.initialFilter;
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildWhenOption(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryText : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryText : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // Airbnb light grey
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: [X]   [ Search Icon  Start your search ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.primaryText),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Start your search',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w500,
                              ),
                              onSubmitted: (val) {
                                Navigator.pop(context, {
                                  'query': val.trim(),
                                  'filter': _selectedFilter,
                                });
                              },
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                _controller.clear();
                              },
                              icon: const Icon(Icons.clear_rounded),
                              color: Colors.grey.shade400,
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 20 + bottomInset,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    
                    // Card 1: Where? (Suggestions only, NO duplicate TextField)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Where?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Suggested searches',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final item = _suggestions[index];
                              return InkWell(
                                onTap: () {
                                  _controller.text = item['query']!;
                                  setState(() {});
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade100),
                                        ),
                                        child: Icon(
                                          item['icon'] as IconData,
                                          color: Colors.grey.shade600,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title']!,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryText,
                                              ),
                                            ),
                                            Text(
                                              item['subtitle']!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Card 2: When?
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'When?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _buildWhenOption('Any', 'All'),
                              const SizedBox(width: 8),
                              _buildWhenOption('Upcoming', 'Upcoming'),
                              const SizedBox(width: 8),
                              _buildWhenOption('Ongoing', 'Ongoing'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Sticky Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F7F7), // Same as full screen page background
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _selectedFilter = 'All';
                        });
                      },
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, {
                          'query': _controller.text.trim(),
                          'filter': _selectedFilter,
                        });
                      },
                      icon: const Icon(Icons.search, size: 18, color: Colors.white),
                      label: const Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.l),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
