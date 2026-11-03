import 'dart:convert';

import 'package:estate_management/constants/constant.dart';
import 'package:estate_management/models/property_model.dart';
import 'package:estate_management/service/property_storage.dart';
import 'package:estate_management/ui/files/add_files_page.dart';
import 'package:estate_management/ui/files/property_details_page.dart';
import 'package:flutter/material.dart';

class PropertyItem {
  final String id;
  final String title;
  final String location;
  final String area;
  final int bedrooms;
  final String floor;
  final String price;
  final String code;
  final String imageUrl;
  final String propertyType;
  final bool isActive;

  const PropertyItem({
    required this.id,
    required this.title,
    required this.location,
    required this.area,
    required this.bedrooms,
    required this.floor,
    required this.price,
    required this.code,
    this.imageUrl = '',
    this.propertyType = 'آپارتمان',
    this.isActive = true,
  });
}

class PropertiesPage extends StatefulWidget {
  final ValueChanged<PropertyItem>? onPropertyTap;
  final VoidCallback? onAddProperty;

  const PropertiesPage({super.key, this.onPropertyTap, this.onAddProperty});

  @override
  State<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _formatPrice(String price) {
    final normalized = _normalizeDigits(price);
    final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return 'قیمت ثبت نشده';

    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return '$formatted تومان';
  }

  String _selectedFilter = 'همه فایل‌ها';

  List<PropertyItem> _properties = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final savedProperties = await PropertyStorage.instance.getAllProperties();

      final items = savedProperties.map(_toPropertyItem).toList();

      // جدیدترین فایل‌ها ابتدا نمایش داده شوند.
      items.sort((a, b) => b.id.compareTo(a.id));

      if (!mounted) return;

      setState(() {
        _properties = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  PropertyItem _toPropertyItem(PropertyModel property) {
    final bedrooms = _parseNumber(property.bedrooms);
    final area = property.area.trim();
    final floor = property.floor.trim();
    final neighborhood = property.neighborhood.trim();
    final price = property.price.trim();

    return PropertyItem(
      id: property.id,
      title: property.title,
      location: neighborhood.isEmpty ? 'محله ثبت نشده' : neighborhood,
      area: area.isEmpty ? 'متراژ نامشخص' : '$area متر',
      bedrooms: bedrooms,
      floor: floor.isEmpty ? 'طبقه نامشخص' : 'طبقه $floor',
      price: _formatPrice(price),
      code: property.id,
      propertyType: property.propertyType,
      imageUrl: property.imagePaths.isNotEmpty ? property.imagePaths.first : '',
      isActive: property.isActive,
    );
  }

  String _normalizeDigits(String value) {
    return value
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
  }

  int _parseNumber(String value) {
    final normalized = _normalizeDigits(value);
    final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');

    return int.tryParse(digits) ?? 0;
  }

  /// قیمت را به تومان تبدیل می‌کند.
  ///
  /// نمونه‌ها:
  /// 25000000000
  /// 25,000,000,000
  /// ۲۵۰۰۰۰۰۰۰۰۰
  /// 25 میلیارد
  ///
  /// اگر قیمت قابل تشخیص نباشد، null برمی‌گرداند.
  int? _parsePriceToToman(String value) {
    final normalized = _normalizeDigits(value).trim();

    if (normalized.isEmpty || normalized.contains('قیمت ثبت نشده')) {
      return null;
    }

    final lower = normalized.toLowerCase();

    // قیمت‌هایی که به صورت «۲۵ میلیارد» یا «۲۵ میلیون» وارد شده‌اند.
    if (lower.contains('میلیارد') || lower.contains('میلیون')) {
      final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(normalized);

      if (match == null) return null;

      final numberText = match.group(0)!.replaceAll(',', '.');
      final number = double.tryParse(numberText);

      if (number == null) return null;

      final multiplier = lower.contains('میلیارد') ? 1000000000 : 1000000;

      return (number * multiplier).round();
    }

    // جداکننده‌های هزارگان و متن‌هایی مثل «تومان» حذف می‌شوند.
    final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return null;

    return int.tryParse(digits);
  }

  List<PropertyItem> get _filteredProperties {
    final query = _normalizeDigits(_searchController.text.trim().toLowerCase());

    return _properties.where((property) {
      final title = _normalizeDigits(property.title.toLowerCase());
      final location = _normalizeDigits(property.location.toLowerCase());
      final code = _normalizeDigits(property.code.toLowerCase());

      final matchesSearch =
          query.isEmpty ||
          title.contains(query) ||
          location.contains(query) ||
          code.contains(query);

      final matchesFilter = switch (_selectedFilter) {
        '۲ خوابه' => property.bedrooms == 2,
        '۳ خوابه' => property.bedrooms == 3,
        '۴ خوابه' => property.bedrooms == 4,
        'ویلایی' =>
          property.propertyType.contains('ویلایی') ||
              property.title.contains('ویلایی'),
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  /// دسته‌بندی قیمت فایل‌های ۲ خوابه.
  Widget _buildTwoBedroomGroups(List<PropertyItem> properties) {
    const billion = 1000000000;

    final groups = <String, List<PropertyItem>>{
      'فایل‌های زیر ۲۰ میلیارد تومان': [],
      'فایل‌های ۲۰ تا ۳۰ میلیارد تومان': [],
      'فایل‌های ۳۰ تا ۴۰ میلیارد تومان': [],
      'فایل‌های بالای ۴۰ میلیارد تومان': [],
      'فایل‌های با قیمت نامشخص': [],
    };

    for (final property in properties) {
      final price = _parsePriceToToman(property.price);

      if (price == null) {
        groups['فایل‌های با قیمت نامشخص']!.add(property);
      } else if (price < 20 * billion) {
        groups['فایل‌های زیر ۲۰ میلیارد تومان']!.add(property);
      } else if (price < 30 * billion) {
        groups['فایل‌های ۲۰ تا ۳۰ میلیارد تومان']!.add(property);
      } else if (price <= 40 * billion) {
        groups['فایل‌های ۳۰ تا ۴۰ میلیارد تومان']!.add(property);
      } else {
        groups['فایل‌های بالای ۴۰ میلیارد تومان']!.add(property);
      }
    }

    return _buildGroupedList(groups);
  }

  /// دسته‌بندی قیمت فایل‌های ۳ خوابه.
  /// فایل‌های زیر ۲۰ میلیارد تومان نمایش داده نمی‌شوند.
  Widget _buildThreeBedroomGroups(List<PropertyItem> properties) {
    const billion = 1000000000;

    final groups = <String, List<PropertyItem>>{
      'فایل‌های ۲۰ تا ۳۰ میلیارد تومان': [],
      'فایل‌های ۳۰ تا ۴۰ میلیارد تومان': [],
      'فایل‌های بالای ۴۰ میلیارد تومان': [],
      'فایل‌های با قیمت نامشخص': [],
    };

    for (final property in properties) {
      final price = _parsePriceToToman(property.price);

      if (price == null) {
        groups['فایل‌های با قیمت نامشخص']!.add(property);
      } else if (price < 20 * billion) {
        // فایل‌های زیر ۲۰ میلیارد در فیلتر ۳ خوابه نمایش داده نمی‌شوند.
        continue;
      } else if (price < 30 * billion) {
        groups['فایل‌های ۲۰ تا ۳۰ میلیارد تومان']!.add(property);
      } else if (price <= 40 * billion) {
        groups['فایل‌های ۳۰ تا ۴۰ میلیارد تومان']!.add(property);
      } else {
        groups['فایل‌های بالای ۴۰ میلیارد تومان']!.add(property);
      }
    }

    return _buildGroupedList(groups);
  }

  /// نمایش مشترک گروه‌های قیمت همراه با تعداد فایل‌ها.
  Widget _buildGroupedList(Map<String, List<PropertyItem>> groups) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final entry in groups.entries)
          if (entry.value.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.files.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.value.length} فایل',
                      style: const TextStyle(
                        color: AppColors.files,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map(
              (property) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PropertyTile(
                  property: property,
                  onTap: () => _openProperty(property),
                ),
              ),
            ),
          ],
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addProperty() async {
    if (widget.onAddProperty != null) {
      widget.onAddProperty!.call();
      await _loadProperties();
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddPropertyPage()));

    if (!mounted) return;
    await _loadProperties();
  }

  Future<void> _openProperty(PropertyItem property) async {
    if (widget.onPropertyTap != null) {
      widget.onPropertyTap!(property);
      return;
    }

    try {
      final savedProperty = await PropertyStorage.instance.getPropertyById(
        property.id,
      );

      if (!mounted) return;

      if (savedProperty == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ملک موردنظر پیدا نشد.')));
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PropertyDetailsPage(property: savedProperty),
        ),
      );

      if (!mounted) return;
      await _loadProperties();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در باز کردن ملک: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = _filteredProperties;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.appBar,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'فایل‌های املاک',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _addProperty,
              tooltip: 'افزودن فایل',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.files,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 26),
            ),
            IconButton(
              onPressed: _loadProperties,
              tooltip: 'بارگذاری مجدد',
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilters(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    const Text(
                      'فایل‌های فروش ثبت‌شده',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _isLoading
                          ? 'در حال بارگذاری...'
                          : '${properties.length} فایل',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.files,
                        ),
                      )
                    : _loadError != null
                    ? _buildErrorState()
                    : properties.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProperties,
                        child: _selectedFilter == '۲ خوابه'
                            ? _buildTwoBedroomGroups(properties)
                            : _selectedFilter == '۳ خوابه'
                            ? _buildThreeBedroomGroups(properties)
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  24,
                                ),
                                itemCount: properties.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final property = properties[index];

                                  return _PropertyTile(
                                    property: property,
                                    onTap: () => _openProperty(property),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'جست‌وجوی ملک، محله یا کد فایل...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.iconMuted,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.iconMuted,
                  ),
                ),
          filled: true,
          fillColor: AppColors.appBar,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.white.withValues(alpha: 0.04),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.files, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = <String>[
      'همه فایل‌ها',
      '۲ خوابه',
      '۳ خوابه',
      '۴ خوابه',
      'ویلایی',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) {
              setState(() => _selectedFilter = filter);
            },
            labelStyle: TextStyle(
              color: isSelected ? AppColors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            selectedColor: AppColors.files,
            backgroundColor: AppColors.appBar,
            side: BorderSide(
              color: isSelected
                  ? AppColors.files
                  : AppColors.white.withValues(alpha: 0.06),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch =
        _searchController.text.trim().isNotEmpty ||
        _selectedFilter != 'همه فایل‌ها';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apartment_rounded,
              size: 54,
              color: AppColors.iconMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'فایلی پیدا نشد' : 'هنوز ملکی ثبت نشده',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'عبارت جست‌وجو یا فیلتر انتخاب‌شده را تغییر بده.'
                  : 'از دکمه + استفاده کن و اولین ملک را ثبت کن.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addProperty,
                icon: const Icon(Icons.add),
                label: const Text('افزودن ملک'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.files,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
            const SizedBox(height: 12),
            const Text(
              'خواندن فایل‌های ذخیره‌شده ناموفق بود.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProperties,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش دوباره'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyTile extends StatelessWidget {
  final PropertyItem property;
  final VoidCallback onTap;

  const _PropertyTile({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBar,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildTypeBadge(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      property.price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.files,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _buildFeature(Icons.square_foot_rounded, property.area),
                        _buildFeature(
                          Icons.bed_outlined,
                          '${property.bedrooms} خواب',
                        ),
                        _buildFeature(Icons.layers_outlined, property.floor),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'کد: ${property.code}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_left_rounded,
                          size: 19,
                          color: AppColors.iconMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    Widget imageWidget;

    if (property.imageUrl.startsWith('data:image/') &&
        property.imageUrl.contains(',')) {
      try {
        final bytes = base64Decode(property.imageUrl.split(',').last);

        imageWidget = Image.memory(
          bytes,
          width: 108,
          height: 145,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _placeholderImage();
          },
        );
      } catch (_) {
        imageWidget = _placeholderImage();
      }
    } else if (property.imageUrl.startsWith('http://') ||
        property.imageUrl.startsWith('https://')) {
      imageWidget = Image.network(
        property.imageUrl,
        width: 108,
        height: 145,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _placeholderImage();
        },
      );
    } else {
      imageWidget = _placeholderImage();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageWidget,
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 108,
      height: 145,
      color: AppColors.avatar,
      alignment: Alignment.center,
      child: const Icon(
        Icons.apartment_rounded,
        size: 42,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.files.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'فروش',
        style: TextStyle(
          color: AppColors.files,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.iconMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
