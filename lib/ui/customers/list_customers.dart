import 'package:estate_management/constants/constant.dart';
import 'package:estate_management/models/customers_model.dart';
import 'package:estate_management/service/property_storage.dart';
import 'package:estate_management/ui/customers/add_customers_page.dart';
import 'package:estate_management/ui/customers/customer_detail_page.dart';
import 'package:flutter/material.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key, this.onCustomerTap, this.onAddCustomer});

  final ValueChanged<CustomerModel>? onCustomerTap;
  final VoidCallback? onAddCustomer;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'همه';

  List<CustomerModel> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _filters = ['همه', 'خریدار', 'فروشنده'];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customers = await PropertyStorage.instance.getAllCustomers();

      if (!mounted) return;

      setState(() {
        _customers = customers.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'خطا در دریافت مشتری‌ها: $e';
      });
    }
  }

  List<CustomerModel> get _filteredCustomers {
    final query = _searchQuery.trim().toLowerCase();

    return _customers.where((customer) {
      final matchesSearch =
          customer.name.toLowerCase().contains(query) ||
          customer.phone.contains(query) ||
          customer.neighborhood.toLowerCase().contains(query) ||
          customer.description.toLowerCase().contains(query);

      final matchesFilter = switch (_selectedFilter) {
        'خریدار' => customer.type == 'buyer',
        'فروشنده' => customer.type == 'seller' || customer.type == 'landlord',
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.appBar,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مشتری‌ها',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'مدیریت مشتریان املاک',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return AddCustomerPage();
                      },
                    ),
                  );
                },
                tooltip: 'افزودن مشتری',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.customers,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 26),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearch(),
              _buildFilters(),
              _buildListHeader(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'جستجوی نام، شماره یا منطقه...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.iconMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.close, color: AppColors.iconMuted),
                )
              : null,
          filled: true,
          fillColor: AppColors.appBar,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.avatar.withValues(alpha: 0.45),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.customers,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedFilter = filter);
            },
            showCheckmark: false,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.background : AppColors.textSecondary,
            ),
            backgroundColor: AppColors.appBar,
            selectedColor: AppColors.customers,
            side: BorderSide(
              color: selected
                  ? AppColors.customers
                  : AppColors.avatar.withValues(alpha: 0.35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          );
        },
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      child: Row(
        children: [
          const Text(
            'لیست مشتری‌ها',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredCustomers.length} نفر',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _loadCustomers,
            tooltip: 'بروزرسانی',
            icon: const Icon(Icons.refresh, color: AppColors.iconMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.customers),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadCustomers,
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    final customers = _filteredCustomers;

    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.iconMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _customers.isEmpty
                  ? 'هنوز مشتری‌ای ثبت نشده است'
                  : 'مشتری‌ای پیدا نشد',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),

      itemBuilder: (context, index) {
        final customer = customers[index];

        return _CustomerTile(
          customer: customer,
          onTap: () async {
            // اگر صفحه‌ای از قبل برای کلیک تعریف شده، اجرا نشود
            // و جزئیات مشتری مستقیماً باز شود.
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => CustomerDetailPage(customer: customer),
              ),
            );

            if (!mounted) return;

            if (changed == true) {
              await _loadCustomers();
            }
          },
        );
      },
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});

  final CustomerModel customer;
  final VoidCallback onTap;

  Color get typeColor => switch (customer.type) {
    'buyer' => AppColors.customers,
    'seller' || 'landlord' => AppColors.files,
    _ => AppColors.iconMuted,
  };

  String get typeLabel => switch (customer.type) {
    'buyer' => 'خریدار',
    'seller' || 'landlord' => 'فروشنده',
    _ => 'نامشخص',
  };

  String get initials {
    final name = customer.name.trim();

    if (name.isEmpty) return '?';

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length > 1) {
      return '${parts.first[0]}${parts[1][0]}';
    }

    return parts.first[0];
  }

  @override
  Widget build(BuildContext context) {
    final location = customer.neighborhood.trim().isNotEmpty
        ? customer.neighborhood
        : 'محله ثبت نشده';

    final budget = customer.budget.trim().isNotEmpty
        ? customer.budget
        : 'ثبت نشده';

    return Material(
      color: AppColors.appBar,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.avatar.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: AppColors.avatar,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name.isEmpty ? 'بدون نام' : customer.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          customer.phone,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(color: typeColor, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_left, color: AppColors.iconMuted),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.avatar),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: AppColors.iconMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 17,
                    color: AppColors.customers,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'بودجه:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      budget,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.customers,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (customer.description.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    customer.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
