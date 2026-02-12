import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'package:dynamic_ui_app/utils/web_stub.dart' as io;
import '../controllers/runtime_controller.dart';
import '../handlers/action_handler.dart';
import '../engine/expression_engine.dart';
import '../engine/style_engine.dart';
import '../engine/layout_engine.dart';

/// Widget that renders native Flutter widgets from JSON configuration
class DynamicRenderer extends StatelessWidget {
  final Map<String, dynamic> json;
  final RuntimeController runtimeController;
  final ActionHandler actionHandler;
  final bool isRTL;

  const DynamicRenderer({
    super.key,
    required this.json,
    required this.runtimeController,
    required this.actionHandler,
    this.isRTL = false,
  });

  @override
  Widget build(BuildContext context) {
    final type = json['type'] as String? ?? 'column';
    
    // Check for conditional visibility using ExpressionEngine
    final visibleIf = json['visibleIf'] as String?;
    if (visibleIf != null) {
      final isVisible = runtimeController.evaluate(visibleIf);
      if (!isVisible) {
        return const SizedBox.shrink();
      }
    }
    
    Widget widget;
    switch (type) {
      case 'screen':
        widget = _renderScreen(context);
        break;
      case 'column':
      case 'row':
      case 'grid':
        // Use LayoutEngine for layout widgets
        widget = LayoutEngine.build(json, runtimeController, actionHandler, isRTL);
        break;
      case 'text':
        widget = _renderText();
        break;
      case 'button':
        widget = _renderButton(context);
        break;
      case 'input':
        widget = _renderInput();
        break;
      case 'select':
        widget = _renderSelect();
        break;
      case 'textarea':
        widget = _renderTextarea();
        break;
      case 'form':
        widget = _renderForm(context);
        break;
      case 'image':
        widget = _renderImage();
        break;
      case 'container':
        widget = _renderContainer(context);
        break;
      case 'tabs':
        widget = _renderTabs(context);
        break;
      case 'console':
        widget = _renderConsole(context);
        break;
      case 'appBar':
        widget = _renderAppBar(context);
        break;
      default:
        widget = LayoutEngine.build(json, runtimeController, actionHandler, isRTL);
    }
    
    // Apply style using StyleEngine
    return StyleEngine.apply(json, widget);
  }

  /// Render a screen widget
  Widget _renderScreen(BuildContext context) {
    // Support both formats:
    // Old: {appBar: {...}, body: {...}}
    // New: {appBar: {...}, layout: {...}} or just {layout: {...}}
    final appBar = json['appBar'] as Map<String, dynamic>?;
    final body = json['body'] as Map<String, dynamic>?;
    final layout = json['layout'] as Map<String, dynamic>?;
    
    // Use layout if available (new format), otherwise use body (old format)
    final content = layout ?? body;
    
    // Extract title from appBar or use id as fallback
    String? title;
    Color? appBarColor;
    if (appBar != null) {
      title = appBar['title'] as String?;
      final appBarStyle = appBar['style'] as Map<String, dynamic>?;
      if (appBarStyle != null && appBarStyle['background'] != null) {
        appBarColor = _parseColor(appBarStyle['background'] as String?);
      }
    }
    if (title == null || title.isEmpty) {
      title = json['id'] as String? ?? 'Screen';
    }
    
    // Extract elevation from appBar style
    double appBarElevation = 4.0;
    if (appBar != null) {
      final appBarStyle = appBar['style'] as Map<String, dynamic>?;
      if (appBarStyle != null && appBarStyle['elevation'] != null) {
        final elevationValue = appBarStyle['elevation'];
        if (elevationValue is int) {
          appBarElevation = elevationValue.toDouble();
        } else if (elevationValue is double) {
          appBarElevation = elevationValue;
        }
      }
    } else {
      appBarElevation = 0.0;
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[100], // Match HTML bg-gray-100
      appBar: appBar != null || title != null
          ? AppBar(
              title: Text(title ?? 'Screen'),
              backgroundColor: appBarColor ?? _parseColor(runtimeController.styles?['primaryColor']) ?? Colors.blue,
              elevation: appBarElevation,
            )
          : null,
      body: content != null
          ? Directionality(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Match HTML p-4
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return DynamicRenderer(
                      json: content,
                      runtimeController: runtimeController,
                      actionHandler: actionHandler,
                      isRTL: isRTL,
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }

  /// Render a column widget
  Widget _renderColumn(BuildContext context) {
    final children = json['children'] as List<dynamic>? ?? [];
    final gap = json['gap'];
    final gapValue = gap != null ? (gap is int ? gap.toDouble() : gap as double?) : null;
    
    // Parse mainAxis alignment
    final mainAxis = json['mainAxis'] as String?;
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;
    if (mainAxis == 'center') {
      mainAxisAlignment = MainAxisAlignment.center;
    } else if (mainAxis == 'end' || mainAxis == 'flex-end') {
      mainAxisAlignment = MainAxisAlignment.end;
    } else if (mainAxis == 'space-between') {
      mainAxisAlignment = MainAxisAlignment.spaceBetween;
    } else if (mainAxis == 'space-around') {
      mainAxisAlignment = MainAxisAlignment.spaceAround;
    }
    
    // Parse crossAxis alignment
    final crossAxis = json['crossAxis'] as String?;
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch;
    if (crossAxis == 'start' || crossAxis == 'flex-start') {
      crossAxisAlignment = CrossAxisAlignment.start;
    } else if (crossAxis == 'center') {
      crossAxisAlignment = CrossAxisAlignment.center;
    } else if (crossAxis == 'end' || crossAxis == 'flex-end') {
      crossAxisAlignment = CrossAxisAlignment.end;
    }
    
    final childrenWidgets = children.map((child) {
      return DynamicRenderer(
        json: child as Map<String, dynamic>,
        runtimeController: runtimeController,
        actionHandler: actionHandler,
        isRTL: isRTL,
      );
    }).toList();
    
    // Add gap between children if specified
    List<Widget> spacedChildren = [];
    if (gapValue != null && gapValue > 0) {
      for (int i = 0; i < childrenWidgets.length; i++) {
        spacedChildren.add(childrenWidgets[i]);
        if (i < childrenWidgets.length - 1) {
          spacedChildren.add(SizedBox(height: gapValue));
        }
      }
    } else {
      spacedChildren = childrenWidgets;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
            ),
            child: Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              children: spacedChildren,
            ),
          ),
        );
      },
    );
  }

  /// Render a row widget
  Widget _renderRow(BuildContext context) {
    final children = json['children'] as List<dynamic>? ?? [];
    final gap = json['gap'];
    final gapValue = gap != null ? (gap is int ? gap.toDouble() : gap as double?) : null;
    
    // Parse mainAxis alignment
    final mainAxis = json['mainAxis'] as String?;
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;
    if (mainAxis == 'center') {
      mainAxisAlignment = MainAxisAlignment.center;
    } else if (mainAxis == 'end' || mainAxis == 'flex-end') {
      mainAxisAlignment = MainAxisAlignment.end;
    } else if (mainAxis == 'space-between') {
      mainAxisAlignment = MainAxisAlignment.spaceBetween;
    } else if (mainAxis == 'space-around') {
      mainAxisAlignment = MainAxisAlignment.spaceAround;
    }
    
    // Parse crossAxis alignment
    final crossAxis = json['crossAxis'] as String?;
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start;
    if (crossAxis == 'start' || crossAxis == 'flex-start') {
      crossAxisAlignment = CrossAxisAlignment.start;
    } else if (crossAxis == 'center') {
      crossAxisAlignment = CrossAxisAlignment.center;
    } else if (crossAxis == 'end' || crossAxis == 'flex-end') {
      crossAxisAlignment = CrossAxisAlignment.end;
    } else if (crossAxis == 'stretch') {
      crossAxisAlignment = CrossAxisAlignment.stretch;
    }
    
    final childrenWidgets = children.map((child) {
      final childJson = child as Map<String, dynamic>;
      final childType = childJson['type'] as String?;
      
      Widget childWidget = DynamicRenderer(
        json: childJson,
        runtimeController: runtimeController,
        actionHandler: actionHandler,
        isRTL: isRTL,
      );
      
      // Wrap widgets that need width constraints in Expanded
      // This includes: input, column, container, row, grid, tabs, select, textarea
      if (childType == 'input' || 
          childType == 'column' || 
          childType == 'container' ||
          childType == 'row' ||
          childType == 'grid' ||
          childType == 'tabs' ||
          childType == 'select' ||
          childType == 'textarea') {
        childWidget = Expanded(
          child: childWidget,
        );
      }
      
      return childWidget;
    }).toList();
    
    // Add gap between children if specified
    List<Widget> spacedChildren = [];
    if (gapValue != null && gapValue > 0) {
      for (int i = 0; i < childrenWidgets.length; i++) {
        spacedChildren.add(childrenWidgets[i]);
        if (i < childrenWidgets.length - 1) {
          spacedChildren.add(SizedBox(width: gapValue));
        }
      }
    } else {
      spacedChildren = childrenWidgets;
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: spacedChildren,
    );
  }

  /// Render a text widget
  Widget _renderText() {
    final value = json['value'] as String? ?? json['text'] as String? ?? '';
    // Handle both int and double for fontSize
    final fontSizeValue = json['fontSize'];
    final fontSize = fontSizeValue != null 
        ? (fontSizeValue is int ? fontSizeValue.toDouble() : fontSizeValue as double?)
        : 16.0;
    final fontWeight = json['fontWeight'] as String?;
    final color = json['color'] as String?;
    
    FontWeight weight = FontWeight.normal;
    if (fontWeight == 'bold') {
      weight = FontWeight.bold;
    } else if (fontWeight == 'light') {
      weight = FontWeight.w300;
    }
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        value,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color != null ? _parseColor(color) : null,
        ),
      ),
    );
  }

  /// Render a button widget
  Widget _renderButton(BuildContext context) {
    final text = json['text'] as String? ?? '';
    final actionId = json['action'] as String?;
    final backgroundColor = json['backgroundColor'] as String?;
    final textColor = json['textColor'] as String?;
    
    final buttonRadius = runtimeController.styles?['buttonRadius'] as int? ?? 12;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: actionId != null
            ? () async {
                await actionHandler.executeAction(actionId);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor != null 
              ? _parseColor(backgroundColor) 
              : _parseColor(runtimeController.styles?['primaryColor']),
          foregroundColor: textColor != null 
              ? _parseColor(textColor) 
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius.toDouble()),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  /// Render a form widget
  Widget _renderForm(BuildContext context) {
    final fields = json['fields'] as List<dynamic>? ?? [];
    final actions = json['actions'] as List<dynamic>? ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...fields.map((field) {
            return _renderFormField(field as Map<String, dynamic>);
          }),
          const SizedBox(height: 16),
          ...actions.map((action) {
            return DynamicRenderer(
              json: action as Map<String, dynamic>,
              runtimeController: runtimeController,
              actionHandler: actionHandler,
              isRTL: isRTL,
            );
          }),
        ],
      ),
    );
  }

  /// Render a form field
  Widget _renderFormField(Map<String, dynamic> field) {
    final type = field['type'] as String? ?? 'text';
    final id = field['id'] as String? ?? '';
    final label = field['label'] as String? ?? '';
    final suffix = field['suffix'] as String?;
    
    switch (type) {
      case 'text':
      case 'number':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextField(
            keyboardType: type == 'number' ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              labelText: label,
              suffixText: suffix,
              border: const OutlineInputBorder(),
            ),
          ),
        );
      case 'switch':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Switch(
                value: false, // TODO: Manage form state
                onChanged: (value) {
                  // TODO: Update form state
                },
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Render an input widget with state binding
  Widget _renderInput() {
    final bindTo = json['bindTo'] as String?;
    final inputType = json['inputType'] as String? ?? 'text';
    final placeholder = json['placeholder'] as String? ?? '';
    
    // Get initial value from state if bindTo exists
    final initialValue = bindTo != null 
        ? runtimeController.getValue(bindTo)?.toString() ?? ''
        : '';
    
    final textController = TextEditingController(text: initialValue);
    
    final textField = TextField(
      controller: textController,
      decoration: InputDecoration(
        labelText: bindTo ?? placeholder,
        hintText: placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: inputType == 'number' 
          ? TextInputType.number 
          : TextInputType.text,
      onChanged: bindTo != null 
          ? (value) {
              // Update state on change
              if (inputType == 'number') {
                final numValue = num.tryParse(value);
                runtimeController.setValue(bindTo, numValue ?? value);
              } else {
                runtimeController.setValue(bindTo, value);
              }
            }
          : null,
    );
    
    // Return TextField with padding - width will be constrained by parent (Expanded in Row, or Column stretch)
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: textField,
    );
  }

  /// Render a select widget
  Widget _renderSelect() {
    final bindTo = json['bindTo'] as String?;
    final options = json['options'] as List<dynamic>? ?? [];
    final placeholder = json['placeholder'] as String? ?? '';
    
    String? selectedValue;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: bindTo ?? placeholder,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: options.map((option) {
          final optionText = option.toString();
          return DropdownMenuItem<String>(
            value: optionText,
            child: Text(optionText),
          );
        }).toList(),
        initialValue: selectedValue,
        onChanged: (value) {
          selectedValue = value;
          // TODO: Update state
        },
      ),
    );
  }

  /// Render a textarea widget
  Widget _renderTextarea() {
    final bindTo = json['bindTo'] as String?;
    final placeholder = json['placeholder'] as String? ?? '';
    final rows = json['rows'] as int? ?? 4;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        maxLines: rows,
        decoration: InputDecoration(
          labelText: bindTo ?? placeholder,
          hintText: placeholder,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// Render an appBar widget
  Widget _renderAppBar(BuildContext context) {
    final title = json['title'] as String? ?? '';
    
    return AppBar(
      title: Text(title),
      backgroundColor: _parseColor(runtimeController.styles?['primaryColor']),
    );
  }

  /// Render a container widget
  Widget _renderContainer(BuildContext context) {
    final children = json['children'] as List<dynamic>? ?? [];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use available width constraints
        return SizedBox(
          width: constraints.maxWidth != double.infinity 
              ? constraints.maxWidth 
              : null, // Let it expand if no constraint
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure children take full width
            children: children.map((child) {
              return DynamicRenderer(
                json: child as Map<String, dynamic>,
                runtimeController: runtimeController,
                actionHandler: actionHandler,
                isRTL: isRTL,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Render an image widget
  Widget _renderImage() {
    final asset = json['asset'] as String?;
    // Handle both int and double for height/width
    final heightValue = json['height'];
    final height = heightValue != null ? (heightValue is int ? heightValue.toDouble() : heightValue as double?) : null;
    final widthValue = json['width'];
    final width = widthValue != null ? (widthValue is int ? widthValue.toDouble() : widthValue as double?) : null;
    
    if (asset == null) {
      return const SizedBox.shrink();
    }
    
    // Get asset path from RuntimeController
    final assetPath = '${runtimeController.runtimePath}/$asset';
    
    // Check if file exists (skip on web)
    if (!kIsWeb && !io.File(assetPath).existsSync()) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: kIsWeb
          ? Image.network(
              assetPath, // On web, use network image
              height: height,
              width: width,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            )
          : Image.file(
              io.File(assetPath),
              height: height,
              width: width,
              fit: BoxFit.contain,
            ),
    );
  }

  /// Render tabs widget (TabBar + TabBarView)
  Widget _renderTabs(BuildContext context) {
    final tabs = json['tabs'] as List<dynamic>? ?? [];
    final initialIndex = json['initialIndex'] as int? ?? 0;
    
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight > 0 
            ? constraints.maxHeight - 50 // פחות גובה TabBar
            : MediaQuery.of(context).size.height * 0.6;
        
        return DefaultTabController(
          length: tabs.length,
          initialIndex: initialIndex,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                isScrollable: true,
                tabs: tabs.map((tab) {
                  final tabData = tab as Map<String, dynamic>;
                  return Tab(
                    text: tabData['label'] as String? ?? '',
                  );
                }).toList(),
              ),
              SizedBox(
                height: availableHeight,
                child: TabBarView(
                  children: tabs.map((tab) {
                    final tabData = tab as Map<String, dynamic>;
                    final content = tabData['content'] as Map<String, dynamic>?;
                    if (content == null) {
                      return const SizedBox.shrink();
                    }
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DynamicRenderer(
                            json: content,
                            runtimeController: runtimeController,
                            actionHandler: actionHandler,
                            isRTL: isRTL,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Render grid widget (supports any number of columns)
  Widget _renderGrid(BuildContext context) {
    final columns = json['columns'] as int? ?? 2;
    final children = json['children'] as List<dynamic>? ?? [];
    final gapValue = json['gap'];
    final gap = gapValue != null ? (gapValue is int ? gapValue.toDouble() : gapValue as double?) : 8.0;
    
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Build rows based on columns count
    List<Widget> rows = [];
    for (int i = 0; i < children.length; i += columns) {
      List<Widget> rowChildren = [];
      for (int j = 0; j < columns && (i + j) < children.length; j++) {
        final child = children[i + j];
        Widget childWidget = Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.only(
              right: j < columns - 1 ? gap! / 2 : 0,
              left: j > 0 ? gap! / 2 : 0,
            ),
            child: DynamicRenderer(
              json: child as Map<String, dynamic>,
              runtimeController: runtimeController,
              actionHandler: actionHandler,
              isRTL: isRTL,
            ),
          ),
        );
        rowChildren.add(childWidget);
      }
      
      // Use Row with start alignment to avoid infinite height issues
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  /// Render console/output widget
  Widget _renderConsole(BuildContext context) {
    final title = json['title'] as String? ?? 'Output';
    final content = json['content'] as String? ?? '';
    final showClearButton = json['showClearButton'] as bool? ?? true;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showClearButton)
                  TextButton(
                    onPressed: () {
                      // Clear console action
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parse color string to Color object
  Color _parseColor(dynamic colorValue) {
    if (colorValue == null) {
      return Colors.blue;
    }
    
    final colorStr = colorValue.toString();
    if (colorStr.startsWith('#')) {
      return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
    }
    
    return Colors.blue;
  }
}

