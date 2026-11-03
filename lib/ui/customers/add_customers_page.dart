import 'package:estate_management/constants/constant.dart';
import 'package:estate_management/models/customers_model.dart';
import 'package:estate_management/service/property_storage.dart';
import 'package:flutter/material.dart';

enum NewCustomerType { buyer, seller }

class AddCustomerPage extends StatefulWidget {
  final ValueChanged<CustomerModel>? onSave;

  const AddCustomerPage({super.key, this.onSave});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _budgetController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _descriptionController = TextEditingController();

  NewCustomerType _customerType = NewCustomerType.buyer;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _budgetController.dispose();
    _neighborhoodController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final customer = CustomerModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      type: _customerType.name,
      budget: _budgetController.text.trim(),
      neighborhood: _neighborhoodController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await PropertyStorage.instance.saveCustomer(customer);

      if (!mounted) return;

      widget.onSave?.call(customer);

      if (!mounted) return;

      if (widget.onSave == null) {
        Navigator.of(context).pop(customer);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مشتری با موفقیت ثبت شد.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ثبت مشتری: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
            'افزودن مشتری',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildLabel('نام و نام خانوادگی'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'نام مشتری را وارد کنید',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'نام مشتری را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildLabel('شماره تماس'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _phoneController,
                hint: '',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'شماره تماس را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildLabel('نوع مشتری'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      title: 'خریدار',
                      icon: Icons.home_outlined,
                      type: NewCustomerType.buyer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeOption(
                      title: 'فروشنده',
                      icon: Icons.real_estate_agent_outlined,
                      type: NewCustomerType.seller,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildLabel('بودجه (تومان)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _budgetController,
                hint: 'بودجه موردنظر را وارد کنید',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              _buildLabel('محله'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _neighborhoodController,
                hint: 'محله موردنظر یا محل ملک',
              ),
              const SizedBox(height: 20),

              _buildLabel('توضیحات'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: 'توضیحات و نیازهای مشتری...',
                maxLines: 4,
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.addCustomer,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.addCustomer.withValues(
                      alpha: 0.6,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Text(
                          'ثبت مشتری',
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

  Widget _buildLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      textDirection: TextDirection.rtl,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required IconData icon,
    required NewCustomerType type,
  }) {
    final isSelected = _customerType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _customerType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.addCustomer.withValues(alpha: 0.12)
              : AppColors.appBar,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.addCustomer
                : AppColors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.addCustomer : AppColors.iconMuted,
              size: 21,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? AppColors.addCustomer
                    : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
