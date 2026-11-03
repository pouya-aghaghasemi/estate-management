import 'package:estate_management/constants/constant.dart';
import 'package:estate_management/models/customers_model.dart';
import 'package:estate_management/service/property_storage.dart';
import 'package:flutter/material.dart';

class CustomerDetailPage extends StatefulWidget {
  final CustomerModel customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late CustomerModel _customer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  String get _typeLabel {
    switch (_customer.type) {
      case 'buyer':
        return 'خریدار';
      case 'seller':
        return 'فروشنده';
      default:
        return _customer.type;
    }
  }

  IconData get _typeIcon {
    return _customer.type == 'buyer'
        ? Icons.home_outlined
        : Icons.real_estate_agent_outlined;
  }

  Future<void> _editCustomer() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditCustomerPage(customer: _customer),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      final updated = await PropertyStorage.instance.getCustomerById(
        _customer.id,
      );

      if (!mounted) return;

      if (updated != null) {
        setState(() => _customer = updated);
      }

      // به صفحه فهرست اعلام می‌کنیم که اطلاعات تغییر کرده است.
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'حذف مشتری',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'آیا از حذف «${_customer.name}» مطمئن هستید؟',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('انصراف', style: TextStyle(color: Colors.white)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _busy = true);

    try {
      await PropertyStorage.instance.deleteCustomer(_customer.id);

      if (!mounted) return;

      // true یعنی مشتری حذف شده و فهرست باید به‌روزرسانی شود.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _busy = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حذف مشتری ناموفق بود: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _info(String label, String value) {
    final displayValue = value.trim().isEmpty ? 'ثبت نشده' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              displayValue,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.addCustomer.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon, color: AppColors.addCustomer, size: 21),
        ),
        const SizedBox(width: 10),
        const Text(
          'اطلاعات مشتری',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _customer;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          toolbarHeight: 56,
          backgroundColor: AppColors.appBar,
          elevation: 0,
          titleSpacing: 16,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          title: const Text(
            'جزئیات مشتری',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _busy
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // کارت معرفی مشتری
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.appBar,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: AppColors.addCustomer.withValues(
                              alpha: 0.14,
                            ),
                            child: Icon(
                              _typeIcon,
                              color: AppColors.addCustomer,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            c.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.addCustomer.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _typeLabel,
                              style: const TextStyle(
                                color: AppColors.addCustomer,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            c.phone,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // اطلاعات کامل
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.appBar,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(),
                          const SizedBox(height: 12),
                          Divider(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.15,
                            ),
                            height: 1,
                          ),
                          const SizedBox(height: 8),
                          _info('نام مشتری', c.name),
                          _info('شماره تماس', c.phone),
                          _info('نوع مشتری', _typeLabel),
                          _info('بودجه (تومان)', c.budget),
                          _info('محله', c.neighborhood),
                          _info('توضیحات', c.description),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ویرایش
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _editCustomer,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text(
                          'ویرایش مشتری',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.addCustomer,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // حذف
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _deleteCustomer,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          'حذف مشتری',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// فرم ویرایش مشتری؛ اطلاعات قبلی را نگه می‌دارد و با همان ID ذخیره می‌کند.
class EditCustomerPage extends StatefulWidget {
  final CustomerModel customer;

  const EditCustomerPage({super.key, required this.customer});

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _budgetController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _descriptionController;

  late String _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final c = widget.customer;

    _nameController = TextEditingController(text: c.name);
    _phoneController = TextEditingController(text: c.phone);
    _budgetController = TextEditingController(text: c.budget);
    _neighborhoodController = TextEditingController(text: c.neighborhood);
    _descriptionController = TextEditingController(text: c.description);
    _type = c.type == 'seller' ? 'seller' : 'buyer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _budgetController.dispose();
    _neighborhoodController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updated = CustomerModel(
        id: widget.customer.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        type: _type,
        budget: _budgetController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      await PropertyStorage.instance.saveCustomer(updated);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ویرایش مشتری: $e')));
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool requiredField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          validator: requiredField
              ? (value) => value == null || value.trim().isEmpty
                    ? '$label را وارد کنید'
                    : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.appBar,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.white.withValues(alpha: 0.06),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.addCustomer,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final selected = _type == value;

    return Expanded(
      child: InkWell(
        onTap: _saving ? null : () => setState(() => _type = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.addCustomer.withValues(alpha: 0.12)
                : AppColors.appBar,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.addCustomer
                  : AppColors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.addCustomer : AppColors.iconMuted,
                size: 21,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: selected
                      ? AppColors.addCustomer
                      : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          title: const Text(
            'ویرایش مشتری',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field(
                label: 'نام و نام خانوادگی',
                controller: _nameController,
                hint: 'نام مشتری را وارد کنید',
                requiredField: true,
              ),
              const SizedBox(height: 20),
              _field(
                label: 'شماره تماس',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                requiredField: true,
              ),
              const SizedBox(height: 20),
              const Text(
                'نوع مشتری',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _typeOption(
                    title: 'خریدار',
                    value: 'buyer',
                    icon: Icons.home_outlined,
                  ),
                  const SizedBox(width: 12),
                  _typeOption(
                    title: 'فروشنده',
                    value: 'seller',
                    icon: Icons.real_estate_agent_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _field(
                label: 'بودجه (تومان)',
                controller: _budgetController,
                hint: 'بودجه موردنظر',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _field(
                label: 'محله',
                controller: _neighborhoodController,
                hint: 'محله موردنظر یا محل ملک',
              ),
              const SizedBox(height: 20),
              _field(
                label: 'توضیحات',
                controller: _descriptionController,
                hint: 'توضیحات و نیازهای مشتری',
                maxLines: 4,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.addCustomer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ذخیره تغییرات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
