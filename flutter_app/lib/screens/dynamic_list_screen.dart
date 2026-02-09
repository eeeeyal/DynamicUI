import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/app_config.dart';
import '../utils/responsive.dart';
import '../widgets/theme_selector.dart';
import '../services/theme_service.dart';

class DynamicListScreen extends StatelessWidget {
  final ScreenConfig screenConfig;
  final ThemeConfig themeConfig;
  final String? assetsPath;

  const DynamicListScreen({
    super.key,
    required this.screenConfig,
    required this.themeConfig,
    this.assetsPath,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final themeService = Provider.of<ThemeService>(context);
    final currentTheme = themeService.currentTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          screenConfig.title,
          style: TextStyle(
            fontSize: responsive.getFontSize(
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
          ),
        ),
        backgroundColor: currentTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSelector(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'התנתק',
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      backgroundColor: currentTheme.backgroundColor,
      body: ResponsiveContainer(
        maxWidth: responsive.isDesktop ? 1200 : null,
        child: screenConfig.items.isEmpty
            ? _buildEmptyState()
            : _buildList(context),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final responsive = Responsive(context);
    
    // Use grid for desktop/tablet, list for mobile
    if (responsive.isDesktop || responsive.isTablet) {
      final columns = responsive.getColumns(
        mobile: 1,
        tablet: 2,
        desktop: 3,
      );
      
      return GridView.builder(
        padding: responsive.getPadding(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: responsive.isDesktop ? 1.5 : 1.2,
        ),
        itemCount: screenConfig.items.length,
        itemBuilder: (context, index) {
          final item = screenConfig.items[index];
          return _buildGridItem(context, item);
        },
      );
    }
    
    return ListView.builder(
      itemCount: screenConfig.items.length,
      padding: responsive.getPadding(),
      itemBuilder: (context, index) {
        final item = screenConfig.items[index];
        return _buildListItem(context, item);
      },
    );
  }
  
  Widget _buildGridItem(BuildContext context, ScreenItem item) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _handleItemTap(context, item),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.icon != null) ...[
                _buildIcon(item.icon!),
                const SizedBox(height: 12),
              ],
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: themeConfig.primaryColorValue,
                ),
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeConfig.secondaryColorValue,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, ScreenItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: item.icon != null ? _buildIcon(item.icon!) : null,
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeConfig.primaryColorValue,
          ),
        ),
        subtitle: item.subtitle != null
            ? Text(
                item.subtitle!,
                style: TextStyle(color: themeConfig.secondaryColorValue),
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _handleItemTap(context, item),
      ),
    );
  }

  Widget _buildIcon(String iconPath) {
    if (assetsPath != null) {
      final fullPath = '$assetsPath/$iconPath';
      final file = File(fullPath);
      
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 40,
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image,
              color: themeConfig.primaryColorValue,
            );
          },
        );
      }
    }
    
    return Icon(
      Icons.image,
      color: themeConfig.primaryColorValue,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: themeConfig.secondaryColorValue,
          ),
          const SizedBox(height: 16),
          Text(
            'No items available',
            style: TextStyle(
              fontSize: 18,
              color: themeConfig.secondaryColorValue,
            ),
          ),
        ],
      ),
    );
  }

  void _handleItemTap(BuildContext context, ScreenItem item) {
    if (item.route != null) {
      // Navigate to route (you can implement navigation logic here)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigate to: ${item.route}'),
        ),
      );
    }
  }
}

