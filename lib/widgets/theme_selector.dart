import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return PopupMenuButton<int>(
      icon: const Icon(Icons.palette),
      tooltip: 'בחר סגנון',
      onSelected: (index) {
        themeService.setTheme(index);
      },
      itemBuilder: (context) {
        return themeService.themes.asMap().entries.map((entry) {
          final index = entry.key;
          final theme = entry.value;
          final isSelected = index == themeService.selectedThemeIndex;
          
          return PopupMenuItem<int>(
            value: index,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  theme.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }
}


