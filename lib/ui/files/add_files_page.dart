import 'dart:convert';

import 'package:estate_management/constants/constant.dart';
import 'package:estate_management/models/property_model.dart';
import 'package:estate_management/service/property_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPropertyPage extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onSave;
  final PropertyModel? property;

  const AddPropertyPage({super.key, this.onSave, this.property});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _yearController = TextEditingController();
  final _floorController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _propertyTypes = [
    'آپارتمان',
    'خانه ویلایی',
    'زمین',
    'مغازه',
  ];

  String _propertyType = 'آپارتمان';

  bool _elevator = true;
  bool _parking = true;
  bool _storage = false;
  bool _isSaving = false;

  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();

    final property = widget.property;
    if (property == null) return;

    _imagePaths = List<String>.from(property.imagePaths);

    _titleController.text = property.title;
    _neighborhoodController.text = property.neighborhood;
    _areaController.text = property.area;
    _bedroomsController.text = property.bedrooms;
    _yearController.text = property.yearBuilt;
    _floorController.text = property.floor;
    _priceController.text = property.price;
    _descriptionController.text = property.description;

    if (_propertyTypes.contains(property.propertyType)) {
      _propertyType = property.propertyType;
    }

    _elevator = property.elevator;
    _parking = property.parking;
    _storage = property.storage;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _neighborhoodController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _yearController.dispose();
    _floorController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // انتخاب چند عکس از گالری
  Future<void> _pickImages() async {
    try {
      final files = await _imagePicker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (!mounted || files.isEmpty) return;

      final newImages = <String>[];

      for (final file in files) {
        final bytes = await file.readAsBytes();
        final name = file.name.toLowerCase();

        final String mimeType;

        if (name.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (name.endsWith('.webp')) {
          mimeType = 'image/webp';
        } else if (name.endsWith('.gif')) {
          mimeType = 'image/gif';
        } else {
          mimeType = 'image/jpeg';
        }

        newImages.add('data:$mimeType;base64,${base64Encode(bytes)}');
      }

      if (!mounted) return;

      setState(() {
        _imagePaths = [..._imagePaths, ...newImages];
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('انتخاب عکس ناموفق بود: $e')));
    }
  }

  // حذف عکس انتخاب‌شده
  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  // نمایش پیش‌نمایش عکس
  Widget _buildImagePreview(String image, int index) {
    Widget imageWidget;

    if (image.startsWith('data:image/') && image.contains(',')) {
      try {
        final bytes = base64Decode(image.split(',').last);

        imageWidget = Image.memory(
          bytes,
          width: 120,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _imagePlaceholder();
          },
        );
      } catch (_) {
        imageWidget = _imagePlaceholder();
      }
    } else if (image.startsWith('http://') || image.startsWith('https://')) {
      imageWidget = Image.network(
        image,
        width: 120,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _imagePlaceholder();
        },
      );
    } else {
      imageWidget = _imagePlaceholder();
    }

    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: imageWidget),
        Positioned(
          top: 4,
          left: 4,
          child: IconButton(
            tooltip: 'حذف عکس',
            onPressed: () => _removeImage(index),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 120,
      height: 110,
      color: AppColors.appBar,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textSecondary,
        size: 30,
      ),
    );
  }

  // ذخیره یا ویرایش ملک
  Future<void> _saveProperty() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final existingProperty = widget.property;

    final property = PropertyModel(
      id:
          existingProperty?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      propertyType: _propertyType,
      neighborhood: _neighborhoodController.text.trim(),
      area: _areaController.text.trim(),
      bedrooms: _bedroomsController.text.trim(),
      yearBuilt: _yearController.text.trim(),
      floor: _floorController.text.trim(),
      price: _priceController.text.trim(),
      elevator: _elevator,
      parking: _parking,
      storage: _storage,
      description: _descriptionController.text.trim(),

      // ذخیره عکس‌های فعلی، شامل عکس‌های تازه انتخاب‌شده
      imagePaths: List<String>.from(_imagePaths),

      // حفظ وضعیت و تاریخ ثبت ملک قبلی
      isActive: existingProperty?.isActive ?? true,
      createdAt: existingProperty?.createdAt ?? now,
    );

    try {
      await PropertyStorage.instance.saveProperty(property);

      if (!mounted) return;

      widget.onSave?.call(property.toMap());

      if (widget.onSave == null) {
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      debugPrint('خطا در ثبت ملک: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطای ثبت: $e'),
          duration: const Duration(seconds: 10),
        ),
      );
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
          title: Text(
            widget.property == null ? 'افزودن فایل جدید' : 'ویرایش فایل ملک',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle(
                  icon: Icons.home_work_outlined,
                  title: 'مشخصات ملک',
                ),
                const SizedBox(height: 12),

                _dropdownField(
                  label: 'نوع ملک',
                  value: _propertyType,
                  items: _propertyTypes,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _propertyType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                _sectionTitle(
                  icon: Icons.payments_outlined,
                  title: 'قیمت فروش',
                ),
                const SizedBox(height: 12),

                _textField(
                  controller: _priceController,
                  label: 'قیمت کل (تومان)',
                  hint: 'مثلاً ۸۵۰۰۰۰۰۰۰۰',
                  icon: Icons.attach_money,
                  requiredField: true,
                  number: true,
                ),
                const SizedBox(height: 24),

                _sectionTitle(icon: Icons.info_outline, title: 'اطلاعات ملک'),
                const SizedBox(height: 12),

                _textField(
                  controller: _titleController,
                  label: 'عنوان فایل',
                  hint: 'مثلاً آپارتمان دوخواب نوساز',
                  icon: Icons.title,
                  requiredField: true,
                ),
                const SizedBox(height: 12),

                _textField(
                  controller: _neighborhoodController,
                  label: 'محله',
                  hint: 'مثلاً سعادت‌آباد',
                  icon: Icons.location_on_outlined,
                  requiredField: true,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _areaController,
                        label: 'متراژ (متر)',
                        icon: Icons.square_foot,
                        requiredField: true,
                        number: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        controller: _bedroomsController,
                        label: 'تعداد خواب',
                        icon: Icons.bed_outlined,
                        number: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _yearController,
                        label: 'سال ساخت',
                        icon: Icons.calendar_month_outlined,
                        number: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        controller: _floorController,
                        label: 'طبقه',
                        icon: Icons.layers_outlined,
                        number: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _sectionTitle(icon: Icons.checklist_outlined, title: 'امکانات'),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _amenityChip(
                      label: 'آسانسور',
                      value: _elevator,
                      onChanged: (value) {
                        setState(() {
                          _elevator = value;
                        });
                      },
                    ),
                    _amenityChip(
                      label: 'پارکینگ',
                      value: _parking,
                      onChanged: (value) {
                        setState(() {
                          _parking = value;
                        });
                      },
                    ),
                    _amenityChip(
                      label: 'انباری',
                      value: _storage,
                      onChanged: (value) {
                        setState(() {
                          _storage = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _sectionTitle(
                  icon: Icons.photo_library_outlined,
                  title: 'عکس‌های ملک',
                ),
                const SizedBox(height: 12),

                // دکمه انتخاب عکس
                InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.appBar,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.addFile, width: 1.2),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.addFile,
                          size: 30,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'انتخاب عکس از گالری',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),

                // پیش‌نمایش عکس‌ها و امکان حذف
                if (_imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagePaths.length,
                      separatorBuilder: (_, index) {
                        return const SizedBox(width: 10);
                      },
                      itemBuilder: (context, index) {
                        return _buildImagePreview(_imagePaths[index], index);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_imagePaths.length} عکس انتخاب شده',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                _sectionTitle(
                  icon: Icons.description_outlined,
                  title: 'توضیحات',
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    label: 'توضیحات تکمیلی ملک',
                    hint: 'توضیحات ملک را وارد کنید...',
                    icon: Icons.notes,
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProperty,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSaving
                          ? 'در حال ذخیره...'
                          : widget.property == null
                          ? 'ثبت فایل'
                          : 'ذخیره تغییرات',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.addFile,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.addFile, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppColors.appBar,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(label: label),
      items: items.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool requiredField = false,
    bool number = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'این فیلد الزامی است';
              }
              return null;
            }
          : null,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: AppColors.iconMuted, size: 21),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.appBar,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF263449)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF263449)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.addFile, width: 1.4),
      ),
    );
  }

  Widget _amenityChip({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      showCheckmark: true,
      checkmarkColor: AppColors.white,
      selectedColor: AppColors.addFile.withValues(alpha: 0.2),
      backgroundColor: AppColors.appBar,
      side: BorderSide(
        color: value ? AppColors.addFile : const Color(0xFF263449),
      ),
      labelStyle: TextStyle(
        color: value ? Colors.black : AppColors.textSecondary,
      ),
    );
  }
}
