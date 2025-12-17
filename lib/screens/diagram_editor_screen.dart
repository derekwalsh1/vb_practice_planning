import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/diagram.dart';
import '../widgets/diagram_painter.dart';

enum DrawingTool { select, circle, square, triangle, line, curve, text, label }

class DiagramEditorScreen extends StatefulWidget {
  final Diagram? initialDiagram;
  final Function(Diagram)? onDiagramChanged;
  final bool embedded;
  
  const DiagramEditorScreen({
    super.key, 
    this.initialDiagram,
    this.onDiagramChanged,
    this.embedded = false,
  });
  
  @override
  State<DiagramEditorScreen> createState() => _DiagramEditorScreenState();
}

class _DiagramEditorScreenState extends State<DiagramEditorScreen> {
  late Diagram _diagram;
  DrawingTool _selectedTool = DrawingTool.select;
  String? _selectedElementId;
  Color _selectedColor = Colors.blue;
  Offset? _drawStart;
  Offset? _drawCurrent;
  Offset? _curveControl;
  bool _drawingCurveControl = false;
  bool _isResizing = false;
  double _resizeSize = 0.1; // Now normalized (0-1)
  final GlobalKey _canvasKey = GlobalKey();
  
  // Court bounds (updated during layout)
  double? _courtLeft;
  double? _courtTop;
  double? _courtWidth;
  double? _courtHeight;
  
  // Convert canvas coordinates to normalized court coordinates (0-1)
  double _toNormalizedX(double canvasX) {
    if (_courtLeft == null || _courtWidth == null) return 0.5;
    return (canvasX - _courtLeft!) / _courtWidth!;
  }
  
  double _toNormalizedY(double canvasY) {
    if (_courtTop == null || _courtHeight == null) return 0.5;
    return (canvasY - _courtTop!) / _courtHeight!;
  }
  
  double _toNormalizedSize(double canvasSize) {
    if (_courtWidth == null) return 0.1;
    return canvasSize / _courtWidth!;
  }
  
  // Convert normalized court coordinates to canvas coordinates
  double _toCanvasX(double normalizedX) {
    if (_courtLeft == null || _courtWidth == null) return 0;
    return _courtLeft! + (normalizedX * _courtWidth!);
  }
  
  double _toCanvasY(double normalizedY) {
    if (_courtTop == null || _courtHeight == null) return 0;
    return _courtTop! + (normalizedY * _courtHeight!);
  }
  
  double _toCanvasSize(double normalizedSize) {
    if (_courtWidth == null) return 30;
    return normalizedSize * _courtWidth!;
  }
  
  void _updateCourtBounds(Size size) {
    // Calculate court bounds (same logic as DiagramPainter)
    final courtPadding = 40.0;
    final availableWidth = size.width - (courtPadding * 2);
    final availableHeight = size.height - (courtPadding * 2);
    
    double courtWidth;
    double courtHeight;
    
    if (_diagram.courtType == CourtType.full) {
      if (availableWidth * 2 <= availableHeight) {
        courtWidth = availableWidth;
        courtHeight = courtWidth * 2;
      } else {
        courtHeight = availableHeight;
        courtWidth = courtHeight / 2;
      }
    } else {
      final minDimension = availableWidth < availableHeight ? availableWidth : availableHeight;
      courtWidth = minDimension;
      courtHeight = minDimension;
    }
    
    _courtLeft = (size.width - courtWidth) / 2;
    _courtTop = (size.height - courtHeight) / 2;
    _courtWidth = courtWidth;
    _courtHeight = courtHeight;
  }
  
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.white,
    Colors.black,
  ];
  
  @override
  void initState() {
    super.initState();
    _diagram = widget.initialDiagram ?? Diagram();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(
        title: const Text('Diagram Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _selectedElementId != null ? _deleteSelected : null,
            tooltip: 'Delete Selected',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveDiagram,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              children: [
                // Court type selector
                Row(
                  children: [
                    const Text('Court: '),
                    const SizedBox(width: 8),
                    SegmentedButton<CourtType>(
                      segments: const [
                        ButtonSegment(
                          value: CourtType.full,
                          label: Text('Full'),
                          icon: Icon(Icons.rectangle_outlined),
                        ),
                        ButtonSegment(
                          value: CourtType.half,
                          label: Text('Half'),
                          icon: Icon(Icons.rectangle_outlined),
                        ),
                      ],
                      selected: {_diagram.courtType},
                      onSelectionChanged: (Set<CourtType> selection) {
                        setState(() {
                          _diagram.courtType = selection.first;
                        });
                        _notifyDiagramChanged();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Drawing tools
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildToolButton(DrawingTool.select, Icons.touch_app, 'Select'),
                      _buildToolButton(DrawingTool.circle, Icons.circle_outlined, 'Circle'),
                      _buildToolButton(DrawingTool.square, Icons.square_outlined, 'Square'),
                      _buildToolButton(DrawingTool.triangle, Icons.change_history, 'Triangle'),
                      _buildToolButton(DrawingTool.line, Icons.remove, 'Line'),
                      _buildToolButton(DrawingTool.curve, Icons.show_chart, 'Curve'),
                      _buildToolButton(DrawingTool.text, Icons.text_fields, 'Text'),
                      _buildToolButton(DrawingTool.label, Icons.label_outline, 'Label'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Color selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Color: '),
                      const SizedBox(width: 8),
                      ..._availableColors.map((color) => _buildColorButton(color)),
                    ],
                  ),
                ),
                if (_selectedElementId != null && _selectedTool == DrawingTool.select) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_isElementResizable()) ...[
                        const Text('Size: '),
                        Expanded(
                          child: Slider(
                            value: _resizeSize,
                            min: 0.02,
                            max: 0.5,
                            divisions: 48,
                            label: (_toCanvasSize(_resizeSize)).round().toString(),
                            onChanged: (value) {
                              setState(() {
                                _resizeSize = value;
                                _applyResize();
                              });
                            },
                          ),
                        ),
                        Text((_toCanvasSize(_resizeSize)).round().toString()),
                        const SizedBox(width: 8),
                      ],
                      IconButton.filled(
                        onPressed: _deleteSelected,
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _updateCourtBounds(Size(constraints.maxWidth, constraints.maxHeight));
                return GestureDetector(
                  onTapDown: _onTapDown,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Container(
                    color: Colors.grey[200],
                    child: CustomPaint(
                      key: _canvasKey,
                      painter: DiagramPainter(
                        diagram: _diagram,
                        selectedElementId: _selectedElementId,
                        drawStart: _drawStart,
                        drawCurrent: _drawCurrent,
                        curveControl: _curveControl,
                        drawingToolName: _selectedTool.name,
                        drawingColor: _selectedColor,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolButton(DrawingTool tool, IconData icon, String label) {
    final isSelected = _selectedTool == tool;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedTool = tool;
            _selectedElementId = null;
          });
        },
      ),
    );
  }
  
  Widget _buildColorButton(Color color) {
    final isSelected = _selectedColor == color;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedColor = color;
          });
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey,
              width: isSelected ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
  
  void _onTapDown(TapDownDetails details) {
    final position = details.localPosition;
    
    if (_selectedTool == DrawingTool.select) {
      _selectElement(position);
    } else if (_selectedTool == DrawingTool.text) {
      _addText(position);
    } else if (_selectedTool == DrawingTool.label) {
      _addLabel(position);
    }
  }
  
  void _onPanStart(DragStartDetails details) {
    final position = details.localPosition;
    
    if (_selectedTool == DrawingTool.select) {
      _selectElement(position);
    } else if (_selectedTool != DrawingTool.text && _selectedTool != DrawingTool.label) {
      setState(() {
        _drawStart = Offset(
          _toNormalizedX(position.dx),
          _toNormalizedY(position.dy),
        );
        _drawCurrent = Offset(
          _toNormalizedX(position.dx),
          _toNormalizedY(position.dy),
        );
      });
    }
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;
    
    if (_selectedTool == DrawingTool.select && _selectedElementId != null) {
      _moveSelectedElement(position);
    } else if (_drawStart != null) {
      setState(() {
        _drawCurrent = Offset(
          _toNormalizedX(position.dx),
          _toNormalizedY(position.dy),
        );
      });
    }
  }
  
  void _onPanEnd(DragEndDetails details) {
    if (_drawStart != null && _drawCurrent != null && _selectedTool != DrawingTool.select) {
      if (_selectedTool == DrawingTool.curve && !_drawingCurveControl) {
        // First phase: set curve control point
        _drawingCurveControl = true;
        _curveControl = Offset(
          (_drawStart!.dx + _drawCurrent!.dx) / 2,
          (_drawStart!.dy + _drawCurrent!.dy) / 2,
        );
        return; // Don't finish yet
      } else if (_selectedTool == DrawingTool.curve && _drawingCurveControl) {
        _addCurve();
      } else {
        _addShape();
      }
    }
    
    _drawStart = null;
    _drawCurrent = null;
    _curveControl = null;
    _drawingCurveControl = false;
  }
  
  bool _isElementResizable() {
    if (_selectedElementId == null) return false;
    final element = _diagram.elements.firstWhere((e) => e.id == _selectedElementId);
    return element is CircleElement || 
           element is SquareElement || 
           element is TriangleElement ||
           element is TextElement ||
           element is LabelElement;
  }
  
  void _selectElement(Offset position) {
    // Find element at position (reverse order for top-most)
    for (var i = _diagram.elements.length - 1; i >= 0; i--) {
      final element = _diagram.elements[i];
      if (_isPositionInElement(position, element)) {
        setState(() {
          _selectedElementId = element.id;
          // Set resize slider to current element size
          if (element is CircleElement) {
            _resizeSize = element.radius;
          } else if (element is SquareElement) {
            _resizeSize = element.size;
          } else if (element is TriangleElement) {
            _resizeSize = element.size;
          } else if (element is TextElement) {
            _resizeSize = element.fontSize / 100.0; // Normalize fontSize (14-50) to ~0.14-0.5
          } else if (element is LabelElement) {
            _resizeSize = element.fontSize / 100.0; // Normalize fontSize (14-50) to ~0.14-0.5
          }
        });
        return;
      }
    }
    
    // No element found, deselect
    setState(() {
      _selectedElementId = null;
    });
  }
  
  bool _isPositionInElement(Offset position, DiagramElement element) {
    if (element is CircleElement) {
      final x = _toCanvasX(element.x);
      final y = _toCanvasY(element.y);
      final radius = _toCanvasSize(element.radius);
      final dx = position.dx - x;
      final dy = position.dy - y;
      return (dx * dx + dy * dy) <= (radius * radius);
    } else if (element is SquareElement) {
      final x = _toCanvasX(element.x);
      final y = _toCanvasY(element.y);
      final size = _toCanvasSize(element.size);
      final halfSize = size / 2;
      return position.dx >= x - halfSize &&
             position.dx <= x + halfSize &&
             position.dy >= y - halfSize &&
             position.dy <= y + halfSize;
    } else if (element is TriangleElement) {
      final x = _toCanvasX(element.x);
      final y = _toCanvasY(element.y);
      final size = _toCanvasSize(element.size);
      final halfSize = size / 2;
      return position.dx >= x - halfSize &&
             position.dx <= x + halfSize &&
             position.dy >= y - halfSize &&
             position.dy <= y + halfSize;
    } else if (element is LineElement) {
      final x1 = _toCanvasX(element.x1);
      final y1 = _toCanvasY(element.y1);
      final x2 = _toCanvasX(element.x2);
      final y2 = _toCanvasY(element.y2);
      
      // Distance from point to line segment
      final lineLength = ((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
      if (lineLength == 0) {
        return ((position.dx - x1) * (position.dx - x1) + (position.dy - y1) * (position.dy - y1)) < 100;
      }
      
      final t = (((position.dx - x1) * (x2 - x1) + (position.dy - y1) * (y2 - y1)) / lineLength).clamp(0.0, 1.0);
      final projX = x1 + t * (x2 - x1);
      final projY = y1 + t * (y2 - y1);
      final distance = ((position.dx - projX) * (position.dx - projX) + (position.dy - projY) * (position.dy - projY));
      
      return distance < 100; // Within 10 pixels
    } else if (element is CurveElement) {
      // Simplified curve selection - check proximity to start, end, or control point
      final x1 = _toCanvasX(element.x1);
      final y1 = _toCanvasY(element.y1);
      final x2 = _toCanvasX(element.x2);
      final y2 = _toCanvasY(element.y2);
      final cx = _toCanvasX(element.controlX);
      final cy = _toCanvasY(element.controlY);
      
      // Check if close to any of the three points
      final distToStart = (position.dx - x1) * (position.dx - x1) + (position.dy - y1) * (position.dy - y1);
      final distToEnd = (position.dx - x2) * (position.dx - x2) + (position.dy - y2) * (position.dy - y2);
      final distToControl = (position.dx - cx) * (position.dx - cx) + (position.dy - cy) * (position.dy - cy);
      
      return distToStart < 100 || distToEnd < 100 || distToControl < 100;
    } else if (element is TextElement || element is LabelElement) {
      final x = element is TextElement ? _toCanvasX(element.x) : _toCanvasX((element as LabelElement).x);
      final y = element is TextElement ? _toCanvasY(element.y) : _toCanvasY((element as LabelElement).y);
      return (position.dx - x).abs() < 50 && (position.dy - y).abs() < 50;
    }
    return false;
  }
  
  void _moveSelectedElement(Offset position) {
    setState(() {
      final element = _diagram.elements.firstWhere((e) => e.id == _selectedElementId);
      
      final normalizedX = _toNormalizedX(position.dx).clamp(0.0, 1.0);
      final normalizedY = _toNormalizedY(position.dy).clamp(0.0, 1.0);
      
      if (element is CircleElement) {
        element.x = normalizedX;
        element.y = normalizedY;
      } else if (element is SquareElement) {
        element.x = normalizedX;
        element.y = normalizedY;
      } else if (element is TriangleElement) {
        element.x = normalizedX;
        element.y = normalizedY;
      } else if (element is TextElement) {
        element.x = normalizedX;
        element.y = normalizedY;
      } else if (element is LabelElement) {
        element.x = normalizedX;
        element.y = normalizedY;
      }
      _notifyDiagramChanged();
    });
  }
  
  void _applyResize() {
    if (_selectedElementId == null) return;
    
    final element = _diagram.elements.firstWhere((e) => e.id == _selectedElementId);
    
    if (element is CircleElement) {
      element.radius = _resizeSize;
    } else if (element is SquareElement) {
      element.size = _resizeSize;
    } else if (element is TriangleElement) {
      element.size = _resizeSize;
    } else if (element is TextElement) {
      element.fontSize = (_resizeSize * 100.0).clamp(10.0, 50.0); // Convert back to fontSize range
    } else if (element is LabelElement) {
      element.fontSize = (_resizeSize * 100.0).clamp(10.0, 50.0); // Convert back to fontSize range
    }
    _notifyDiagramChanged();
  }
  
  void _addShape() {
    if (_drawStart == null || _drawCurrent == null) return;
    
    final id = const Uuid().v4();
    
    setState(() {
      switch (_selectedTool) {
        case DrawingTool.circle:
          final dx = _drawCurrent!.dx - _drawStart!.dx;
          final dy = _drawCurrent!.dy - _drawStart!.dy;
          final radiusNormalized = math.sqrt(dx * dx + dy * dy).clamp(0.02, 0.3);
          _diagram.elements.add(CircleElement(
            id: id,
            x: _drawStart!.dx.clamp(0.0, 1.0),
            y: _drawStart!.dy.clamp(0.0, 1.0),
            radius: radiusNormalized,
            color: _selectedColor.value,
          ));
          break;
          
        case DrawingTool.square:
          final sizeNormalized = (_drawCurrent! - _drawStart!).distance.clamp(0.02, 0.3);
          _diagram.elements.add(SquareElement(
            id: id,
            x: _drawStart!.dx.clamp(0.0, 1.0),
            y: _drawStart!.dy.clamp(0.0, 1.0),
            size: sizeNormalized,
            color: _selectedColor.value,
          ));
          break;
          
        case DrawingTool.triangle:
          final sizeNormalized = (_drawCurrent! - _drawStart!).distance.clamp(0.02, 0.3);
          _diagram.elements.add(TriangleElement(
            id: id,
            x: _drawStart!.dx.clamp(0.0, 1.0),
            y: _drawStart!.dy.clamp(0.0, 1.0),
            size: sizeNormalized,
            color: _selectedColor.value,
          ));
          break;
          
        case DrawingTool.line:
          _diagram.elements.add(LineElement(
            id: id,
            x1: _drawStart!.dx.clamp(0.0, 1.0),
            y1: _drawStart!.dy.clamp(0.0, 1.0),
            x2: _drawCurrent!.dx.clamp(0.0, 1.0),
            y2: _drawCurrent!.dy.clamp(0.0, 1.0),
            color: _selectedColor.value,
            arrow: true,
          ));
          break;
          
        default:
          break;
      }
      _notifyDiagramChanged();
    });
  }
  
  void _addCurve() {
    if (_drawStart == null || _drawCurrent == null || _curveControl == null) return;
    
    final id = const Uuid().v4();
    
    setState(() {
      _diagram.elements.add(CurveElement(
        id: id,
        x1: _drawStart!.dx.clamp(0.0, 1.0),
        y1: _drawStart!.dy.clamp(0.0, 1.0),
        x2: _drawCurrent!.dx.clamp(0.0, 1.0),
        y2: _drawCurrent!.dy.clamp(0.0, 1.0),
        controlX: _curveControl!.dx.clamp(0.0, 1.0),
        controlY: _curveControl!.dy.clamp(0.0, 1.0),
        color: _selectedColor.value,
        arrow: true,
      ));
      _notifyDiagramChanged();
    });
  }
  
  void _addText(Offset position) {
    _showTextDialog((text) {
      final id = const Uuid().v4();
      setState(() {
        _diagram.elements.add(TextElement(
          id: id,
          x: _toNormalizedX(position.dx).clamp(0.0, 1.0),
          y: _toNormalizedY(position.dy).clamp(0.0, 1.0),
          text: text,
          color: _selectedColor.value,
        ));
        _notifyDiagramChanged();
      });
    });
  }
  
  void _addLabel(Offset position) {
    _showTextDialog((text) {
      final id = const Uuid().v4();
      setState(() {
        _diagram.elements.add(LabelElement(
          id: id,
          x: _toNormalizedX(position.dx).clamp(0.0, 1.0),
          y: _toNormalizedY(position.dy).clamp(0.0, 1.0),
          text: text,
          color: Colors.white.value,
          backgroundColor: _selectedColor.value,
          fontSize: 18.0,
        ));
        _notifyDiagramChanged();
      });
    });
  }
  
  void _showTextDialog(Function(String) onSubmit) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter text or number',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              onSubmit(value);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSubmit(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _deleteSelected() {
    if (_selectedElementId == null) return;
    
    setState(() {
      _diagram.elements.removeWhere((e) => e.id == _selectedElementId);
      _selectedElementId = null;
    });
    _notifyDiagramChanged();
  }
  
  void _notifyDiagramChanged() {
    if (widget.onDiagramChanged != null) {
      widget.onDiagramChanged!(_diagram);
    }
  }
  
  void _saveDiagram() {
    if (widget.embedded) {
      _notifyDiagramChanged();
    } else {
      Navigator.pop(context, _diagram);
    }
  }
}
