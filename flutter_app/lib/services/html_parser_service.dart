import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../utils/responsive.dart';

/// Service to parse HTML and convert to Flutter Widgets
class HtmlParserService {
  /// Parse HTML string and convert to Flutter Widget
  Widget parseHtmlToWidget(String htmlContent, {String? assetsPath, BuildContext? context}) {
    try {
      final document = html_parser.parse(htmlContent);
      final body = document.body;
      
      if (body == null) {
        return const Center(child: Text('No content found'));
      }
      
      // Check for two-column layout
      final hasTwoColumnLayout = _detectTwoColumnLayout(body);
      
      Widget widget;
      if (hasTwoColumnLayout && context != null && !Responsive(context).isMobile) {
        // Parse as two-column layout
        widget = _parseTwoColumnLayout(body, assetsPath: assetsPath, context: context);
      } else {
        widget = _parseElement(body, assetsPath: assetsPath, context: context);
      }
      
      // Wrap in responsive container if context is provided
      if (context != null) {
        final responsive = Responsive(context);
        return ResponsiveContainer(
          maxWidth: responsive.isDesktop ? 1400 : null, // Wider for desktop layouts
          child: widget,
        );
      }
      
      return widget;
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error parsing HTML: $e'),
          ],
        ),
      );
    }
  }

  /// Detect two-column layout pattern
  bool _detectTwoColumnLayout(html_dom.Element element) {
    final directChildren = element.nodes.whereType<html_dom.Element>().toList();
    
    // Check if has exactly 2 main children
    if (directChildren.length == 2) {
      return true;
    }
    
    // Check for common two-column patterns
    final hasLeftRight = directChildren.any((child) {
      final classes = child.classes;
      return classes.contains('left') || 
             classes.contains('right') ||
             classes.contains('sidebar') ||
             classes.contains('main');
    });
    
    return hasLeftRight;
  }

  /// Parse two-column layout
  Widget _parseTwoColumnLayout(html_dom.Element element, {String? assetsPath, BuildContext? context}) {
    if (context == null) {
      return _parseElement(element, assetsPath: assetsPath, context: context);
    }
    
    final responsive = Responsive(context);
    final directChildren = element.nodes.whereType<html_dom.Element>().toList();
    
    if (directChildren.length >= 2) {
      // Find left/right or first/second panels
      html_dom.Element? leftPanel;
      html_dom.Element? rightPanel;
      
      for (final child in directChildren) {
        final classes = child.classes;
        final id = child.id.toLowerCase();
        
        if (classes.contains('left') || 
            classes.contains('sidebar') ||
            (classes.contains('panel') && id.contains('left')) ||
            classes.contains('output') ||
            classes.contains('console')) {
          leftPanel = child;
        } else if (classes.contains('right') ||
                   classes.contains('main') ||
                   classes.contains('content') ||
                   classes.contains('settings') ||
                   classes.contains('config')) {
          rightPanel = child;
        }
      }
      
      // If not found by classes, use first two children
      leftPanel ??= directChildren[0];
      rightPanel ??= directChildren.length > 1 ? directChildren[1] : null;
      
      if (rightPanel != null) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: responsive.isDesktop ? 3 : 2,
              child: Container(
                padding: responsive.getPadding(),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(right: BorderSide(color: Colors.grey[300]!)),
                ),
                child: _parseElement(leftPanel, assetsPath: assetsPath, context: context),
              ),
            ),
            Expanded(
              flex: responsive.isDesktop ? 7 : 5,
              child: Container(
                padding: responsive.getPadding(),
                child: _parseElement(rightPanel, assetsPath: assetsPath, context: context),
              ),
            ),
          ],
        );
      }
    }
    
    return _parseElement(element, assetsPath: assetsPath, context: context);
  }

  /// Parse HTML element to Flutter Widget
  Widget _parseElement(html_dom.Element element, {String? assetsPath, BuildContext? context}) {
    final tagName = element.localName?.toLowerCase() ?? '';
    
    switch (tagName) {
      case 'div':
      case 'section':
      case 'article':
        return _parseContainer(element, assetsPath: assetsPath, context: context);
      
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return _parseHeading(element, context: context);
      
      case 'p':
        return _parseParagraph(element, context: context);
      
      case 'button':
      case 'a':
        return _parseButton(element, context: context);
      
      case 'img':
        return _parseImage(element, assetsPath: assetsPath, context: context);
      
      case 'ul':
      case 'ol':
        return _parseList(element, assetsPath: assetsPath, context: context);
      
      case 'form':
        return _parseForm(element, assetsPath: assetsPath, context: context);
      
      case 'input':
        return _parseInput(element, context: context);
      
      case 'table':
        return _parseTable(element, assetsPath: assetsPath, context: context);
      
      case 'span':
      case 'strong':
      case 'b':
      case 'em':
      case 'i':
        return _parseText(element, context: context);
      
      default:
        // For unknown tags, try to render children
        return _parseChildren(element, assetsPath: assetsPath, context: context);
    }
  }

  /// Parse container element (div, section, etc.)
  Widget _parseContainer(html_dom.Element element, {String? assetsPath, BuildContext? context}) {
    final children = _parseChildren(element, assetsPath: assetsPath, context: context);
    
    // Check for flex/row/column classes
    final classes = element.classes;
    final isRow = classes.contains('row') || 
                  classes.contains('flex-row') ||
                  classes.contains('flex') ||
                  classes.contains('horizontal');
    final isColumn = classes.contains('column') || 
                     classes.contains('flex-column') ||
                     classes.contains('vertical');
    
    // Responsive adjustments
    if (context != null) {
      final responsive = Responsive(context);
      
      // For desktop/tablet, detect two-panel layouts
      if (!responsive.isMobile && element.children.length >= 2) {
        // Check if children look like panels (have specific classes or structure)
        final childElements = element.nodes.whereType<html_dom.Element>().toList();
        final hasPanelLayout = childElements.any((child) {
          final childClasses = child.classes;
          return childClasses.contains('panel') ||
                 childClasses.contains('sidebar') ||
                 childClasses.contains('main') ||
                 childClasses.contains('left') ||
                 childClasses.contains('right');
        });
        
        if (hasPanelLayout && childElements.length == 2) {
          // Two-panel layout - wrap children in Expanded to prevent unbounded width
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: responsive.isDesktop ? 3 : 2,
                child: _parseElement(childElements[0], assetsPath: assetsPath, context: context),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: responsive.isDesktop ? 7 : 5,
                child: _parseElement(childElements[1], assetsPath: assetsPath, context: context),
              ),
            ],
          );
        }
      }
      
      // For mobile, convert rows to columns if needed
      if (isRow && responsive.isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _getChildrenWidgets(element, assetsPath: assetsPath, context: context),
        );
      }
    }
    
    if (isRow) {
      final children = _getChildrenWidgets(element, assetsPath: assetsPath, context: context);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((child) {
          // Wrap in Flexible to prevent unbounded width issues
          return Flexible(child: child);
        }).toList(),
      );
    } else if (isColumn || element.children.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _getChildrenWidgets(element, assetsPath: assetsPath, context: context),
      );
    }
    
    final padding = context != null 
        ? Responsive(context).getPadding()
        : _parsePadding(element);
    
    return Container(
      padding: padding,
      margin: _parseMargin(element),
      decoration: _parseDecoration(element),
      child: children,
    );
  }

  /// Parse heading element
  Widget _parseHeading(html_dom.Element element, {BuildContext? context}) {
    final text = element.text.trim();
    final tagName = element.localName?.toLowerCase() ?? 'h1';
    
    double fontSize;
    FontWeight fontWeight = FontWeight.bold;
    
    switch (tagName) {
      case 'h1':
        fontSize = context != null 
            ? Responsive(context).getFontSize(mobile: 24, tablet: 28, desktop: 32)
            : 32;
        break;
      case 'h2':
        fontSize = context != null 
            ? Responsive(context).getFontSize(mobile: 20, tablet: 24, desktop: 28)
            : 28;
        break;
      case 'h3':
        fontSize = context != null 
            ? Responsive(context).getFontSize(mobile: 18, tablet: 20, desktop: 24)
            : 24;
        break;
      case 'h4':
        fontSize = context != null 
            ? Responsive(context).getFontSize(mobile: 16, tablet: 18, desktop: 20)
            : 20;
        break;
      case 'h5':
        fontSize = context != null 
            ? Responsive(context).getFontSize(mobile: 14, tablet: 16, desktop: 18)
            : 18;
        break;
      case 'h6':
        fontSize = context != null 
            ? Responsive(context).getFontSize(mobile: 12, tablet: 14, desktop: 16)
            : 16;
        break;
      default:
        fontSize = 24;
    }
    
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: _parseColor(element),
      ),
    );
  }

  /// Parse paragraph element
  Widget _parseParagraph(html_dom.Element element, {BuildContext? context}) {
    final fontSize = context != null
        ? Responsive(context).getFontSize(mobile: 14, tablet: 16, desktop: 18)
        : 16.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context != null 
            ? Responsive(context).value(mobile: 8.0, tablet: 10.0, desktop: 12.0)
            : 8.0,
      ),
      child: Text(
        element.text.trim(),
        style: TextStyle(
          fontSize: fontSize,
          color: _parseColor(element),
        ),
      ),
    );
  }

  /// Parse text element
  Widget _parseText(html_dom.Element element, {BuildContext? context}) {
    final tagName = element.localName?.toLowerCase() ?? '';
    FontWeight? fontWeight;
    FontStyle? fontStyle;
    
    if (tagName == 'strong' || tagName == 'b') {
      fontWeight = FontWeight.bold;
    } else if (tagName == 'em' || tagName == 'i') {
      fontStyle = FontStyle.italic;
    }
    
    return Text(
      element.text.trim(),
      style: TextStyle(
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: _parseColor(element),
      ),
    );
  }

  /// Parse button element
  Widget _parseButton(html_dom.Element element, {BuildContext? context}) {
    final text = element.text.trim();
    final href = element.attributes['href'];
    
    final padding = context != null
        ? Responsive(context).value(
            mobile: 8.0,
            tablet: 10.0,
            desktop: 12.0,
          )
        : 8.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: ElevatedButton(
        onPressed: () {
          // Handle navigation or action
          debugPrint('Button pressed: $text, href: $href');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _parseBackgroundColor(element) ?? Colors.blue,
          foregroundColor: _parseColor(element) ?? Colors.white,
          padding: context != null
              ? Responsive(context).getPadding(
                  mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                )
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          text.isEmpty ? (href ?? 'Button') : text,
          style: TextStyle(
            fontSize: context != null
                ? Responsive(context).getFontSize(mobile: 14, tablet: 16, desktop: 18)
                : 16,
          ),
        ),
      ),
    );
  }

  /// Parse image element
  Widget _parseImage(html_dom.Element element, {String? assetsPath, BuildContext? context}) {
    final src = element.attributes['src'] ?? element.attributes['data-src'] ?? '';
    final alt = element.attributes['alt'] ?? '';
    
    if (src.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Responsive image sizing
    double? width;
    if (context != null) {
      final responsive = Responsive(context);
      width = responsive.value<double>(
        mobile: responsive.width * 0.9,
        tablet: responsive.width * 0.7,
        desktop: 400,
      );
    }
    
    // Check if it's a local asset
    if (assetsPath != null && !src.startsWith('http')) {
      final imagePath = '$assetsPath/$src';
      return Image.asset(
        imagePath,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text(alt.isNotEmpty ? alt : 'Image not found');
        },
      );
    }
    
    // Network image
    if (src.startsWith('http')) {
      return Image.network(
        src,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text(alt.isNotEmpty ? alt : 'Image failed to load');
        },
      );
    }
    
    return Text(alt.isNotEmpty ? alt : 'Image: $src');
  }

  /// Parse list element
  Widget _parseList(html_dom.Element element, {String? assetsPath, BuildContext? context}) {
    final isOrdered = element.localName?.toLowerCase() == 'ol';
    final items = element.querySelectorAll('li');
    
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOrdered ? '${index + 1}.' : '•',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _parseChildren(item, assetsPath: assetsPath),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Parse form element
  Widget _parseForm(html_dom.Element element, {String? assetsPath, BuildContext? context}) {
    return Column(
      children: _getChildrenWidgets(element, assetsPath: assetsPath, context: context),
    );
  }

  /// Parse input element
  Widget _parseInput(html_dom.Element element, {BuildContext? context}) {
    final type = element.attributes['type']?.toLowerCase() ?? 'text';
    final placeholder = element.attributes['placeholder'] ?? '';
    final name = element.attributes['name'] ?? '';
    
    switch (type) {
      case 'text':
      case 'email':
      case 'password':
        final padding = context != null
            ? Responsive(context).value(mobile: 8.0, tablet: 10.0, desktop: 12.0)
            : 8.0;
        
        final textField = TextField(
          decoration: InputDecoration(
            labelText: placeholder.isNotEmpty ? placeholder : name,
            border: const OutlineInputBorder(),
            contentPadding: context != null
                ? Responsive(context).getPadding(
                    mobile: const EdgeInsets.all(12),
                    tablet: const EdgeInsets.all(14),
                    desktop: const EdgeInsets.all(16),
                  )
                : const EdgeInsets.all(12),
          ),
          obscureText: type == 'password',
          keyboardType: type == 'email' 
              ? TextInputType.emailAddress 
              : TextInputType.text,
          style: TextStyle(
            fontSize: context != null
                ? Responsive(context).getFontSize(mobile: 14, tablet: 16, desktop: 18)
                : 16,
          ),
        );
        
        // Wrap in SizedBox to prevent unbounded width
        return Padding(
          padding: EdgeInsets.symmetric(vertical: padding),
          child: SizedBox(
            width: double.infinity,
            child: textField,
          ),
        );
      
      case 'button':
      case 'submit':
        return ElevatedButton(
          onPressed: () {},
          child: Text(placeholder.isNotEmpty ? placeholder : 'Submit'),
        );
      
      default:
        return TextField(
          decoration: InputDecoration(
            labelText: placeholder.isNotEmpty ? placeholder : name,
            border: const OutlineInputBorder(),
          ),
        );
    }
  }

  /// Parse table element
  Widget _parseTable(html_dom.Element element, {String? assetsPath, BuildContext? context}) {
    final rows = element.querySelectorAll('tr');
    
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final cellPadding = context != null
        ? Responsive(context).getPadding(
            mobile: const EdgeInsets.all(6.0),
            tablet: const EdgeInsets.all(8.0),
            desktop: const EdgeInsets.all(10.0),
          )
        : const EdgeInsets.all(8.0);
    
    final fontSize = context != null
        ? Responsive(context).getFontSize(mobile: 12, tablet: 14, desktop: 16)
        : 14.0;
    
    return SingleChildScrollView(
      scrollDirection: context != null && Responsive(context).isMobile 
          ? Axis.horizontal 
          : Axis.vertical,
      child: Table(
        border: TableBorder.all(),
        children: rows.map((row) {
          final cells = row.querySelectorAll('td, th');
          return TableRow(
            children: cells.map((cell) {
              return Padding(
                padding: cellPadding,
                child: Text(
                  cell.text.trim(),
                  style: TextStyle(fontSize: fontSize),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  /// Parse children elements
  Widget _parseChildren(html_dom.Element element, {String? assetsPath, BuildContext? context}) {
    final children = _getChildrenWidgets(element, assetsPath: assetsPath, context: context);
    
    if (children.isEmpty) {
      return Text(element.text.trim());
    }
    
    if (children.length == 1) {
      return children.first;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Get children widgets
  List<Widget> _getChildrenWidgets(html_dom.Element element, {String? assetsPath, BuildContext? context}) {
    return element.nodes.whereType<html_dom.Element>().map((child) {
      return _parseElement(child, assetsPath: assetsPath, context: context);
    }).toList();
  }

  /// Parse padding from element
  EdgeInsets _parsePadding(html_dom.Element element) {
    // Simple padding parsing - can be extended
    // TODO: Parse CSS padding from style attribute
    return const EdgeInsets.all(8.0);
  }

  /// Parse margin from element
  EdgeInsets _parseMargin(html_dom.Element element) {
    // Simple margin parsing - can be extended
    // TODO: Parse CSS margin from style attribute
    return EdgeInsets.zero;
  }

  /// Parse decoration from element
  BoxDecoration? _parseDecoration(html_dom.Element element) {
    final bgColor = _parseBackgroundColor(element);
    if (bgColor != null) {
      return BoxDecoration(color: bgColor);
    }
    return null;
  }

  /// Parse color from element
  Color? _parseColor(html_dom.Element element) {
    // TODO: Parse CSS color from style attribute
    return null;
  }

  /// Parse background color from element
  Color? _parseBackgroundColor(html_dom.Element element) {
    // TODO: Parse CSS background-color from style attribute
    return null;
  }
}

