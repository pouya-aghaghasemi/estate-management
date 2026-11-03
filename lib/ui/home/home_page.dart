import 'package:estate_management/constants/constant.dart';
import 'package:estate_management/ui/customers/add_customers_page.dart';
import 'package:estate_management/ui/customers/list_customers.dart';
import 'package:estate_management/ui/files/add_files_page.dart';
import 'package:estate_management/ui/files/list_files.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          toolbarHeight: 56,
          backgroundColor: AppColors.appBar,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(
            children: [
              const Icon(Icons.home_rounded, color: AppColors.files, size: 27),
              const SizedBox(width: 7),
              const Text(
                'املاک من',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.nightlight_round,
                  color: AppColors.iconMuted,
                  size: 21,
                ),
              ),
              const SizedBox(width: 4),
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.avatar,
                child: Icon(Icons.person, size: 19, color: AppColors.white),
              ),
              const SizedBox(width: 7),
              const Text(
                'مدیر',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isSmall = screenWidth < 400;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 12 : 20,
                  vertical: isSmall ? 12 : 20,
                ),
                child: Column(
                  children: [
                    // Four cards use all remaining height.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, gridConstraints) {
                          const spacing = 12.0;

                          final cardWidth =
                              (gridConstraints.maxWidth - spacing) / 2;
                          final cardHeight =
                              (gridConstraints.maxHeight - spacing) / 2;
                          return GridView.count(
                            padding: EdgeInsets.zero,
                            crossAxisCount: 2,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            childAspectRatio: cardWidth / cardHeight,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              HomeCard(
                                title: 'فایل‌ها',
                                subtitle: 'مشاهده فایل‌های ملکی',
                                icon: Icons.description_outlined,
                                color: AppColors.files,
                                compact: isSmall,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return PropertiesPage();
                                      },
                                    ),
                                  );
                                },
                              ),
                              HomeCard(
                                title: 'مشتری‌ها',
                                subtitle: 'مدیریت مشتری‌ها',
                                icon: Icons.people_alt_outlined,
                                color: AppColors.customers,
                                compact: isSmall,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CustomersPage(),
                                    ),
                                  );
                                },
                              ),
                              HomeCard(
                                title: 'افزودن فایل',
                                subtitle: 'ثبت ملک جدید',
                                icon: Icons.post_add_rounded,
                                color: AppColors.addFile,
                                compact: isSmall,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddPropertyPage(
                                        onSave: (customer) {
                                          // بعداً مشتری را به لیست اضافه می‌کنیم.
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              HomeCard(
                                title: 'افزودن مشتری',
                                subtitle: 'ثبت مشتری جدید',
                                icon: Icons.person_add_alt_1_rounded,
                                color: AppColors.addCustomer,
                                compact: isSmall,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddCustomerPage(
                                        onSave: (customer) {
                                          // بعداً مشتری را به لیست اضافه می‌کنیم.
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const HomeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.15),
        child: Container(
          padding: EdgeInsets.all(compact ? 8 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.24), width: 1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shortCard = constraints.maxHeight < 150;
              final iconSize = shortCard
                  ? 38.0
                  : compact
                  ? 46.0
                  : 64.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.19),
                      borderRadius: BorderRadius.circular(compact ? 13 : 18),
                    ),
                    child: Icon(icon, color: color, size: iconSize * 0.53),
                  ),
                  SizedBox(height: shortCard ? 7 : 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: compact ? 15 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: shortCard ? 4 : 7),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: compact ? 10 : 12,
                        ),
                      ),
                    ),
                  ),
                  if (!shortCard) ...[
                    SizedBox(height: compact ? 7 : 12),
                    Container(
                      width: compact ? 29 : 36,
                      height: compact ? 29 : 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: color,
                        size: compact ? 17 : 21,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
