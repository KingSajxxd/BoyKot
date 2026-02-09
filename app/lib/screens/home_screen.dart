import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/boycott_service.dart';
import '../widgets/brand_detail_card.dart';
import '../widgets/brand_logo_block.dart';
import '../widgets/toll_header.dart';
import '../widgets/quote_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BoycottService _service = BoycottService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  Map<String, dynamic>? _data;
  
  List<dynamic> _allBrands = [];
  Map<String, dynamic> _brandMap = {}; 
  List<dynamic> _searchResults = [];
  
  bool _showScrollToTop = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Set status bar style for light theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _loadData();
    _fetchLiveToll();
    _scrollController.addListener(_handleScroll);
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final shouldShow = _scrollController.offset > 400;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadData() async {
    final loadedData = await _service.loadData();
    if (!mounted || loadedData == null) return;

    final items = loadedData['items'] as List<dynamic>? ?? [];
    
    final Map<String, dynamic> map = {};
    final List<dynamic> all = [];

    for (final item in items) {
      if (item['name'] != null) {
        map[item['name'].toString().toLowerCase()] = item;
      }
      all.add(item);
    }

    all.sort((a, b) => 
      (a['name'] as String).compareTo(b['name'] as String)
    );

    setState(() {
      _data = loadedData;
      _allBrands = all;
      _brandMap = map;
    });
  }

  Future<void> _fetchLiveToll() async {
    final toll = await _service.fetchLiveToll();
    if (!mounted || toll == null) return;

    setState(() {
      _data ??= {};
      _data!['toll'] = toll;
    });
  }

  void _runSearch(String keyword) {
    if (_data == null) return;
    if (keyword.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final searchLower = keyword.toLowerCase();

    setState(() {
      _isSearching = true;
      _searchResults = _allBrands.where((item) {
        final name = item['name'].toString().toLowerCase();
        final subbrands = item['subbrands'] != null
            ? (item['subbrands'] as List).join(' ').toLowerCase()
            : '';
        return name.contains(searchLower) || subbrands.contains(searchLower);
      }).toList();
    });
  }

  void _showBrandDetail(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              height: 5,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: BrandDetailCard(
                  item: item, 
                  isModal: true,
                  brandMap: _brandMap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final toll = _data != null ? _data!['toll'] : null;
    final displayList = _isSearching ? _searchResults : _allBrands;
    final bool isSearchActive = _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;

    return Scaffold(
      floatingActionButton: AnimatedScale(
        scale: _showScrollToTop ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: _scrollToTop,
          elevation: 4,
          child: const Icon(Icons.keyboard_arrow_up_rounded, size: 28),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
          slivers: [
            // App Header
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: isSearchActive ? 0.0 : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSearchActive ? 0.0 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          // App Logo and Name
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BoyKot',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Stand for Palestine',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Palestine Flag Colors
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                _buildFlagStripe(const Color(0xFF1A1A1A)),
                                _buildFlagStripe(Colors.white, hasBorder: true),
                                _buildFlagStripe(const Color(0xFF007A3D)),
                                const SizedBox(width: 4),
                                Container(
                                  width: 0,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFCE1126),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: CustomPaint(
                                    size: const Size(8, 16),
                                    painter: TrianglePainter(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Quote Carousel
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: isSearchActive ? 0.0 : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSearchActive ? 0.0 : 1.0,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 20),
                      child: QuoteCarousel(),
                    ),
                  ),
                ),
              ),
            ),
            
            // Death Toll Header
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: isSearchActive ? 0.0 : null, 
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSearchActive ? 0.0 : 1.0,
                    child: toll != null ? TollHeader(toll: toll) : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            
            // Search Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: isSearchActive ? 0.0 : null,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isSearchActive ? 0.0 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Check a Brand',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A1A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Search to verify before you buy',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Search Field
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _runSearch,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search company or product...',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.grey.shade400,
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _runSearch('');
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Brand Results
            if (_isSearching && displayList.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No brands found',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try a different search term',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isSearching)
              // Search Results List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 6.0,
                    ),
                    child: BrandDetailCard(
                      item: displayList[index],
                      brandMap: _brandMap,
                    ),
                  ),
                  childCount: displayList.length,
                ),
              )
            else
              // Browse Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return BrandLogoBlock(
                        item: displayList[index],
                        onTap: () => _showBrandDetail(context, displayList[index]),
                      );
                    },
                    childCount: displayList.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagStripe(Color color, {bool hasBorder = false}) {
    return Container(
      width: 8,
      height: 16,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: color,
        border: hasBorder ? Border.all(color: Colors.grey.shade300, width: 0.5) : null,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCE1126)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}