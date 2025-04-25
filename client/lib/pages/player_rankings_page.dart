import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PlayerRankingsPage extends StatefulWidget {
  const PlayerRankingsPage({super.key});

  @override
  State<PlayerRankingsPage> createState() => _PlayerRankingsPageState();
}

class _PlayerRankingsPageState extends State<PlayerRankingsPage> {
  final ApiService _apiService = ApiService();

  // 更新颜色以匹配图片中的绿色调
  final Color _primaryColor = const Color(0xFF4CD964);
  final Color _secondaryColor = const Color(0xFF121212);
  final Color _backgroundColor = const Color(0xFF1A1A1A);

  // 添加上升下降颜色
  final Color _upColor = const Color(0xFF4CD964); // 绿色
  final Color _downColor = const Color(0xFFFF3B30); // 红色
  final Color _neutralColor = const Color(0xFFE6C200); // 黄色

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<dynamic> _players = [];
  List<dynamic> _filteredPlayers = [];
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _debounce;

  // 添加筛选选项
  bool _showATP = true;
  bool _showWTA = false;
  bool _showSingles = true;
  bool _showDoubles = false;

  @override
  void initState() {
    super.initState();
    _loadPlayerRankings();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 加载球员排名数据
  Future<void> _loadPlayerRankings() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final players = await _apiService.getPlayerRankings();

      setState(() {
        _players = players;
        _filteredPlayers = List.from(players);
        _isLoading = false;
        _hasMoreData = false; // 一次性加载所有数据
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('加载排名数据失败: $e');
    }
  }

  // 搜索输入变化处理
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isEmpty) {
        setState(() {
          _showSearchResults = false;
          _searchResults = [];
        });
        return;
      }

      _searchPlayers(_searchController.text);
    });
  }

  // 搜索球员
  Future<void> _searchPlayers(String keyword) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _apiService.searchPlayers(keyword);

      setState(() {
        _searchResults = results;
        _showSearchResults = true;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('搜索球员失败: $e');
    }
  }

  // 滚动监听器
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreData) {
      // 如果需要分页加载，可以在这里实现
    }
  }

  // 下拉刷新
  Future<void> _refreshData() async {
    await _loadPlayerRankings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Players & Rankings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Container(
        // 添加背景渐变效果

        child: Column(
          children: [
            // 筛选选项
            _buildFilterOptions(),

            // 搜索栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search Player...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (value) {
                    setState(() {
                      _showSearchResults = false;
                    });
                    if (value.isNotEmpty) {
                      _searchPlayers(value);
                    }
                  },
                ),
              ),
            ),

            // 搜索结果下拉列表
            if (_showSearchResults)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 300),
                child: _isSearching
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final player = _searchResults[index];
                          return ListTile(
                            title: Text(
                              '${player['Name']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Rank #${player['RankNo']}',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                player['UrlHeadshotImage'] ??
                                    'https://via.placeholder.com/40',
                              ),
                              backgroundColor: Colors.grey[800],
                            ),
                            onTap: () {
                              setState(() {
                                _searchController.text = '${player['Name']}';
                                _showSearchResults = false;
                              });
                            },
                          );
                        },
                      ),
              ),

            // 表头
            _buildTableHeader(),

            // 球员列表
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: RefreshIndicator(
                        onRefresh: _refreshData,
                        color: const Color(0xFF94E831),
                        child: _isLoading && _players.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount: _filteredPlayers.length,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                itemBuilder: (context, index) {
                                  final player = _filteredPlayers[index];
                                  return _buildPlayerItem(player, index + 1);
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建筛选选项
  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Show:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // ATP 按钮
              _buildFilterButton('ATP', _showATP, () {
                setState(() {
                  _showATP = true;
                  _showWTA = false;
                });
              }),
              const SizedBox(width: 8),
              // WTA 按钮
              _buildFilterButton('WTA', _showWTA, () {
                setState(() {
                  _showATP = false;
                  _showWTA = true;
                });
              }),
              const Spacer(),
              // Singles 按钮
              _buildFilterButton('Singles', _showSingles, () {
                setState(() {
                  _showSingles = true;
                  _showDoubles = false;
                });
              }),
              const SizedBox(width: 8),
              // Doubles 按钮
              _buildFilterButton('Doubles', _showDoubles, () {
                setState(() {
                  _showSingles = false;
                  _showDoubles = true;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  // 构建筛选按钮
  Widget _buildFilterButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF94E831) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF94E831)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 构建表头
  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Name
          const SizedBox(width: 16),
          const Expanded(
            flex: 3,
            child: Text(
              'Name',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Rank
          const Expanded(
            flex: 1,
            child: Text(
              'Rank',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Change
          const Expanded(
            flex: 1,
            child: Text(
              'Change',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Country
          const Expanded(
            flex: 2,
            child: Text(
              'Country',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // 构建球员列表项
  Widget _buildPlayerItem(dynamic player, int rank) {
    final String name = player['Name'] ?? '';
    final String countryCode = player['CountryCode'] ?? '';
    final String points = player['Points'] ?? "";
    final int movement = player['Movement'] ?? 0;
    final String urlCountryFlag = player['UrlCountryFlag'] ?? '';

    // 确定排名变化的颜色和图标
    Color movementColor = _neutralColor;
    IconData movementIcon = Icons.remove;
    if (movement > 0) {
      movementColor = _upColor;
      movementIcon = Icons.arrow_drop_up;
    } else if (movement < 0) {
      movementColor = _downColor;
      movementIcon = Icons.arrow_drop_down;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Name
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$points',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Rank
            Expanded(
              flex: 1,
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Change
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    movementIcon,
                    color: movementColor,
                    size: 16,
                  ),
                  Text(
                    movement == 0 ? '0' : movement.abs().toString(),
                    style: TextStyle(
                      color: movementColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Country Flag & Code
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 国旗图片
                  Container(
                    width: 24,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(urlCountryFlag),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) => const AssetImage(
                            'assets/images/flags/placeholder.png'),
                      ),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  // 国家代码
                  Text(
                    countryCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建加载指示器
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: _primaryColor,
        strokeWidth: 2,
      ),
    );
  }
}
