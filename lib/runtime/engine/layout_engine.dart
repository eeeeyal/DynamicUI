import 'package:flutter/material.dart';
import '../controllers/runtime_controller.dart';
import '../handlers/action_handler.dart';
import '../widgets/dynamic_renderer.dart';

/// Engine for building layout widgets (Row, Column, Grid)
class LayoutEngine {
  /// Build a layout widget from JSON
  static Widget build(Map<String, dynamic> json, RuntimeController controller, ActionHandler actionHandler, bool isRTL) {
    final type = json['type'] as String? ?? 'column';
    final children = json['children'] as List<dynamic>? ?? [];
    
    switch (type) {
      case 'row':
        return _buildRow(json, children, controller, actionHandler, isRTL);
      
      case 'column':
        return _buildColumn(json, children, controller, actionHandler, isRTL);
      
      case 'grid':
        return _buildGrid(json, children, controller, actionHandler, isRTL);
      
      default:
        return _buildColumn(json, children, controller, actionHandler, isRTL);
    }
  }
  
  /// Build a Row widget
  static Widget _buildRow(
    Map<String, dynamic> json,
    List<dynamic> children,
    RuntimeController controller,
    ActionHandler actionHandler,
    bool isRTL,
  ) {
    final gap = json['gap'];
    final gapValue = gap != null ? (gap is int ? gap.toDouble() : gap as double?) : null;
    
    final childrenWidgets = children.map((child) {
      final childJson = child as Map<String, dynamic>;
      final childType = childJson['type'] as String?;
      
      Widget childWidget = DynamicRenderer(
        json: childJson,
        runtimeController: controller,
        actionHandler: actionHandler,
        isRTL: isRTL,
      );
      
      // Wrap widgets that need width constraints in Expanded
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
      mainAxisAlignment: _parseMainAxis(json['mainAxis'] as String?),
      crossAxisAlignment: _parseCrossAxis(json['crossAxis'] as String?),
      children: spacedChildren,
    );
  }
  
  /// Build a Column widget
  static Widget _buildColumn(
    Map<String, dynamic> json,
    List<dynamic> children,
    RuntimeController controller,
    ActionHandler actionHandler,
    bool isRTL,
  ) {
    final gap = json['gap'];
    final gapValue = gap != null ? (gap is int ? gap.toDouble() : gap as double?) : null;
    
    final childrenWidgets = children.map((child) {
      return DynamicRenderer(
        json: child as Map<String, dynamic>,
        runtimeController: controller,
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
              mainAxisAlignment: _parseMainAxis(json['mainAxis'] as String?),
              crossAxisAlignment: _parseCrossAxis(json['crossAxis'] as String?),
              children: spacedChildren,
            ),
          ),
        );
      },
    );
  }
  
  /// Build a Grid widget
  static Widget _buildGrid(
    Map<String, dynamic> json,
    List<dynamic> children,
    RuntimeController controller,
    ActionHandler actionHandler,
    bool isRTL,
  ) {
    final columns = json['columns'] as int? ?? 2;
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
              runtimeController: controller,
              actionHandler: actionHandler,
              isRTL: isRTL,
            ),
          ),
        );
        rowChildren.add(childWidget);
      }
      
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
  
  /// Parse MainAxisAlignment from string
  static MainAxisAlignment _parseMainAxis(String? value) {
    if (value == null) return MainAxisAlignment.start;
    
    switch (value.toLowerCase()) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
      case 'flex-end':
        return MainAxisAlignment.end;
      case 'space-between':
        return MainAxisAlignment.spaceBetween;
      case 'space-around':
        return MainAxisAlignment.spaceAround;
      case 'space-evenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }
  
  /// Parse CrossAxisAlignment from string
  static CrossAxisAlignment _parseCrossAxis(String? value) {
    if (value == null) return CrossAxisAlignment.start;
    
    switch (value.toLowerCase()) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
      case 'flex-end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.start;
    }
  }
}

