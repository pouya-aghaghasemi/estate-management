import 'dart:convert';

import 'package:estate_management/constants/constant.dart';
import 'package:estate_management/models/property_model.dart';
import 'package:estate_management/service/property_storage.dart';
import 'package:estate_management/ui/files/add_files_page.dart';
import 'package:flutter/material.dart';

class PropertyDetailsPage extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailsPage({super.key, required this.property});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  late PropertyModel _property;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
  }

  Future<void> _editProperty() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddPropertyPage(property: _property),
      ),
    );

    if (!mounted) return;

    final updated = await PropertyStorage.instance.getPropertyById(
      _property.id,
    );

    if (!mounted) return;

    if (updated != null) {
      setState(() {
        _property = updated;
      });
    }

    if (result == true) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteProperty() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'حذف ملک',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'آیا از حذف «${_property.title}» مطمئن هستید؟',
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
      await PropertyStorage.instance.deleteProperty(_property.id);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _busy = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حذف ملک ناموفق بود: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildPropertyImages() {
    final images = _property.imagePaths
        .where((path) => path.trim().isNotEmpty)
        .toList();

    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFullImage(images, index),
            child: Container(
              width: 300,
              height: 230,
              decoration: BoxDecoration(
                color: AppColors.appBar,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.15),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _buildSingleImage(images[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleImage(String imagePath) {
    if (imagePath.startsWith('data:image/') && imagePath.contains(',')) {
      try {
        final bytes = base64Decode(imagePath.split(',').last);

        return Image.memory(
          bytes,
          width: 300,
          height: 230,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imageError(),
        );
      } catch (_) {
        return _imageError();
      }
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: 300,
        height: 230,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }

    return _imageError();
  }

  Widget _imageError() {
    return Container(
      color: AppColors.appBar,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        size: 42,
        color: AppColors.textSecondary.withValues(alpha: 0.7),
      ),
    );
  }

  void _showFullImage(List<String> images, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final pageController = PageController(initialPage: initialIndex);

        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(dialogContext).size.height * 0.75,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      child: Center(child: _buildSingleImage(images[index])),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _info(String label, String value) {
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
            child: Text(
              value.isEmpty ? 'ثبت نشده' : value,
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

  @override
  Widget build(BuildContext context) {
    final p = _property;

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
            'جزئیات ملک',
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
                    _buildPropertyImages(),

                    if (p.imagePaths.any((path) => path.trim().isNotEmpty))
                      const SizedBox(height: 20),

                    Text(
                      p.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.appBar,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.15,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.files.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: AppColors.files,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'اطلاعات ملک',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Divider(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.15,
                            ),
                            height: 1,
                          ),

                          const SizedBox(height: 8),

                          _info('نوع ملک', p.propertyType),
                          _info('محله', p.neighborhood),
                          _info('متراژ', '${p.area} متر'),
                          _info('تعداد اتاق', p.bedrooms),
                          _info('سال ساخت', p.yearBuilt),
                          _info('طبقه', p.floor),
                          _info('قیمت', '${p.price} تومان'),
                          _info('آسانسور', p.elevator ? 'دارد' : 'ندارد'),
                          _info('پارکینگ', p.parking ? 'دارد' : 'ندارد'),
                          _info('انباری', p.storage ? 'دارد' : 'ندارد'),
                          _info('توضیحات', p.description),

                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Text(
                                  'وضعیت',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (p.isActive
                                                ? AppColors.files
                                                : Colors.red)
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    p.isActive ? 'فعال' : 'غیرفعال',
                                    style: TextStyle(
                                      color: p.isActive
                                          ? AppColors.files
                                          : Colors.red.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _editProperty,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text(
                          'ویرایش ملک',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.files,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _deleteProperty,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          'حذف ملک',
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
