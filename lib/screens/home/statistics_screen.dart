import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'dart:io';
import '../../models/device.dart';
import '../../services/api_service.dart';
import '../../widgets/copyable_text.dart';
import 'qr_code/qr_scan_screen.dart';
import 'qr_code/device_qr_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Device> _devices = [];
  List<Device> _filteredDevices = [];
  bool _isLoading = true;
  String? _error;

  // Filter variables
  String? _selectedFilter;
  DateTime? _fromDate;
  DateTime? _toDate;
  
  // Pagination & counters from API
  int _page = 1;
  final int _limit = 20; // As specified
  int _total = 0;
  int _activeCount = 0;
  int _totalPages = 0;
  
  // Temporary filter variables for bottom sheet
  String? _tempSelectedFilter;
  DateTime? _tempFromDate;
  DateTime? _tempToDate;
  
  // Track current selections in bottom sheet
  Set<String> _currentSelections = {};

  // Infinite scroll
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasLoggedEndForCurrentPage = false;

    // Helper function to format date in HH:mm dd/MM/yyyy format (ISO 8601 with timezone)
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
  }

  // Helper function to format date only in dd-MM-yyyy format (for date picker)
  String _formatDateOnly(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return '$day-$month-$year';
  }



  @override
  void initState() {
    super.initState();
    _loadDevices();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bool? activeFilter = _selectedFilter == 'activated'
          ? true
          : (_selectedFilter == 'not_activated' ? false : null);
      final result = await ApiService.getInventoryDevices(
        page: _page,
        limit: _limit,
        isActive: activeFilter,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      final devices = (result['devices'] as List<Device>);
      setState(() {
        _devices = devices;
        _filteredDevices = devices;
        _total = (result['total'] as int?) ?? devices.length;
        _activeCount = (result['activeCount'] as int?) ?? devices.where((d) => d.isActive).length;
        _totalPages = (result['totalPages'] as int?) ?? 1;
        _isLoading = false;
        _hasLoggedEndForCurrentPage = false;
      });
      print('[Statistics] Loaded page: $_page/$_totalPages, items on page: ${devices.length}, total: $_total, active: $_activeCount');
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách devices: $e';
        print(_error);
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    final position = _scrollController.position;

    // Log when user reaches (almost) the very end of the list once per page
    if (position.pixels >= position.maxScrollExtent - 16 && !_hasLoggedEndForCurrentPage) {
      _hasLoggedEndForCurrentPage = true;
      print('[Statistics] Reached end of list. page=$_page/$_totalPages, loadedItems=${_filteredDevices.length}, pixels=${position.pixels.toStringAsFixed(1)}/${position.maxScrollExtent.toStringAsFixed(1)}');
    }

    if (position.pixels >= position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _page < _totalPages) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _page + 1;
    print('[Statistics] Loading next page: $nextPage');
    try {
      final bool? activeFilter = _selectedFilter == 'activated'
          ? true
          : (_selectedFilter == 'not_activated' ? false : null);
      final result = await ApiService.getInventoryDevices(
        page: nextPage,
        limit: _limit,
        isActive: activeFilter,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      final devices = (result['devices'] as List<Device>);
      setState(() {
        _devices.addAll(devices);
        _page = nextPage;
        _total = (result['total'] as int?) ?? _total;
        _activeCount = (result['activeCount'] as int?) ?? _activeCount;
        _totalPages = (result['totalPages'] as int?) ?? _totalPages;
        _isLoadingMore = false;
        _hasLoggedEndForCurrentPage = false; // allow logging for new page end
      });
      print('[Statistics] Loaded page: $_page/$_totalPages, appended: ${devices.length}, totalLoaded=${_devices.length}');
      _filterDevices();
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      print('[Statistics] Load next page failed: $e');
    }
  }

  void _filterDevices() {
    List<Device> filtered = _devices;
    
    // Apply status filter
    if (_selectedFilter != null) {
      switch (_selectedFilter) {
        case 'activated':
          filtered = filtered.where((device) => device.isActive).toList();
          break;
        case 'not_activated':
          filtered = filtered.where((device) => !device.isActive).toList();
          break;
      }
    }
    
    // Apply date range filter
    if (_fromDate != null || _toDate != null) {
      filtered = filtered.where((device) {
        final deviceDate = device.createdAt;
        if (_fromDate != null && deviceDate.isBefore(_fromDate!)) {
          return false;
        }
        if (_toDate != null && deviceDate.isAfter(_toDate!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }
    
    setState(() {
      _filteredDevices = filtered;
    });
  }

  void _showScanQR(BuildContext context) {
    // Kiểm tra platform trước khi mở scan
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _showPlatformNotSupportedDialog(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScanScreen()),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate, StateSetter setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? (_tempFromDate ?? DateTime.now()) : (_tempToDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setModalState(() {
        if (isFromDate) {
          _tempFromDate = picked;
        } else {
          _tempToDate = picked;
        }
        if (_tempFromDate != null || _tempToDate != null) {
          _currentSelections.add('date_range');
        }
      });
    }
  }

  void _showFilterOptions() {
    // Initialize temporary variables with current values
    _tempSelectedFilter = _selectedFilter;
    _tempFromDate = _fromDate;
    _tempToDate = _toDate;
    
    // Initialize current selections
    _currentSelections.clear();
    if (_tempSelectedFilter != null) {
      _currentSelections.add(_tempSelectedFilter!);
    }
    if (_tempFromDate != null || _tempToDate != null) {
      _currentSelections.add('date_range');
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                const Text(
                  'Bộ lọc và sắp xếp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Status Filter Options
                const Text(
                  'Lọc theo trạng thái:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                
                // Removed 'Tất cả' option per requirement
                
                Column(
                  children: [
                    _buildFilterOption(
                      'Chưa kích hoạt',
                      'not_activated',
                      Icons.cancel,
                      _tempSelectedFilter == 'not_activated',
                      _currentSelections.contains('not_activated'),
                      (value) {
                        setModalState(() {
                          _tempSelectedFilter = value;
                          _currentSelections.add('not_activated');
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFilterOption(
                      'Đã kích hoạt',
                      'activated',
                      Icons.check_circle,
                      _tempSelectedFilter == 'activated',
                      _currentSelections.contains('activated'),
                      (value) {
                        setModalState(() {
                          _tempSelectedFilter = value;
                          _currentSelections.add('activated');
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Date Range Selection
                const Text(
                  'Chọn khoảng thời gian:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true, setModalState),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _tempFromDate != null ? Colors.deepPurple.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _tempFromDate != null ? Colors.deepPurple : Colors.grey.withOpacity(0.3),
                              width: _tempFromDate != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _tempFromDate != null 
                                      ? _formatDateOnly(_tempFromDate!)
                                      : 'Từ ngày',
                                  style: TextStyle(
                                    color: _tempFromDate != null ? Colors.deepPurple : Colors.black87,
                                    fontWeight: _tempFromDate != null ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false, setModalState),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _tempToDate != null ? Colors.deepPurple.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _tempToDate != null ? Colors.deepPurple : Colors.grey.withOpacity(0.3),
                              width: _tempToDate != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _tempToDate != null 
                                      ? _formatDateOnly(_tempToDate!)
                                      : 'Đến ngày',
                                  style: TextStyle(
                                    color: _tempToDate != null ? Colors.deepPurple : Colors.black87,
                                    fontWeight: _tempToDate != null ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setModalState(() {
                            _tempSelectedFilter = null;
                            _tempFromDate = null;
                            _tempToDate = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Xóa bộ lọc'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedFilter = _tempSelectedFilter;
                            _fromDate = _tempFromDate;
                            _toDate = _tempToDate;
                            _page = 1; // reset to first page when applying filters
                          });
                          _loadDevices(); // fetch with filters on server
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildFilterOption(String title, String? value, IconData icon, bool isSelected, bool hasCurrentSelection, Function(String?) onTap) {
    // Check if this is the current filter (not just selected in bottom sheet)
    bool isCurrentFilter = (value == null && _selectedFilter == null) || 
                          (value == _selectedFilter);
    
    // Show border for newly selected items, but check icon only for current filter
    bool showBorder = isSelected;
    bool showCheckIcon = isCurrentFilter;
    
    return InkWell(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: showBorder ? Colors.deepPurple : Colors.grey.withOpacity(0.3),
            width: showBorder ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.deepPurple : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (showCheckIcon)
              const Icon(Icons.check, color: Colors.deepPurple, size: 20),
          ],
        ),
      ),
    );
  }



  void _showPlatformNotSupportedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Không hỗ trợ'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tính năng Scan QR Code chỉ hỗ trợ trên ứng dụng mobile.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Vui lòng sử dụng ứng dụng trên thiết bị Android hoặc iOS để scan mã QR.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê mã QR'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Bộ lọc',
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadDevices,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: () => _showScanQR(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDevices,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }



    return Column(
      children: [
        // Thống kê tổng quan
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Tổng số',
                    _total.toString(),
                    Icons.devices_other,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Đã kích hoạt',
                    _activeCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Chưa kích hoạt',
                    (_total - _activeCount).toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Filter Status Display
        if (_selectedFilter != null || _fromDate != null || _toDate != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.deepPurple, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getFilterStatusText(),
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.deepPurple, size: 16),
                  onPressed: () {
                    setState(() {
                      _selectedFilter = null;
                      _fromDate = null;
                      _toDate = null;
                      _page = 1;
                    });
                    _loadDevices();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        if (_selectedFilter != null || _fromDate != null || _toDate != null)
          const SizedBox(height: 12),
          
        const SizedBox(height: 8),
        // Danh sách devices
        Expanded(
          child: _filteredDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.devices_other, color: Colors.grey, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        (_selectedFilter != null || _fromDate != null || _toDate != null)
                            ? 'Không tìm thấy device nào phù hợp'
                            : 'Không có device nào',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 4,
                  radius: const Radius.circular(4),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredDevices.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoadingMore && index == _filteredDevices.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final device = _filteredDevices[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                        title: CopyableText(
                          text: 'Mã: ${device.macAddress}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          copyMessage: 'Đã copy MAC Address',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CopyableText(
                              text: 'Mã thiết bị: ${device.skuCode}',
                              style: const TextStyle(fontSize: 14),
                              copyMessage: 'Đã copy mã thiết bị',
                            ),
                            CopyableText(
                              text: 'Trạng thái: ${_getPaymentStatusText(device.paymentStatus)}',
                              style: const TextStyle(fontSize: 14),
                              copyMessage: 'Đã copy trạng thái',
                            ),
                            CopyableText(
                              text: 'Ngày tạo: ${_formatDateTime(device.createdAt)}',
                              style: const TextStyle(fontSize: 14),
                              copyMessage: 'Đã copy ngày tạo',
                            ),
                            if (device.customerId != null)
                              CopyableText(
                                text: 'KH: ${device.customerId}',
                                style: const TextStyle(fontSize: 14),
                                copyMessage: 'Đã copy khách hàng',
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: device.isActive ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                device.isActive ? 'Kích hoạt' : 'Chưa kích hoạt',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.qr_code),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceQrScreen(
                                device: device,
                                macAddress: device.macAddress,
                              ),
                            ),
                          );
                        },
                        ),
                      );
                    },
                  ),
                ),
        ),
        // Pagination controls
        // Remove manual pagination UI; infinite scroll handles loading
      ],
    );
  }

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'free':
        return 'Miễn phí';
      case 'paid':
        return 'Đã thanh toán';
      case 'pending':
        return 'Chờ thanh toán';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _getFilterStatusText() {
    List<String> filters = [];
    
    if (_selectedFilter != null) {
      switch (_selectedFilter) {
        case 'activated':
          filters.add('Đã kích hoạt');
          break;
        case 'not_activated':
          filters.add('Chưa kích hoạt');
          break;
      }
    }
    
    if (_fromDate != null || _toDate != null) {
      filters.add('Khoảng thời gian: ${_fromDate != null ? _formatDateOnly(_fromDate!) : 'Từ ngày'} - ${_toDate != null ? _formatDateOnly(_toDate!) : 'Đến ngày'}');
    }
    
    return filters.join(' • ');
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
