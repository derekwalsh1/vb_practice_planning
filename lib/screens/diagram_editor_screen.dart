import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/diagram.dart';
import '../widgets/diagram_painter.dart';

enum DrawingTool { select, circle, square, triangle, line, curve, text, label }

class DiagramEditorScreen extends StatefulWidget {
  final Diagram? initialDiagram;
  
  const DiagramEditorScreen({super.key, this.initialDiagram});
  
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
      appBar: AppBar(
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
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: GestureDetector(
              onTapDown: _onTapDown,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                color: Colors.grey[200],
                child: CustomPaint(
                  painter: DiagramPainter(
                    diagram: _diagram,
                    selectedElementId: _selectedElementId,
                  ),
                  size: Size.infinite,
                ),
              ),
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
      _drawStart = position;
      _drawCurrent = position;
    }
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;
    
    if (_selectedTool == DrawingTool.select && _selectedElementId != null) {
      _moveSelectedElement(position);
    } else if (_drawStart != null) {
      setState(() {
        _drawCurrent = position;
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
  
  void _selectElement(Offset position) {
    // Find element at position (reverse order for top-most)
    for (var i = _diagram.elements.length - 1; i >= 0; i--) {
      final element = _diagram.elements[i];
      if (_isPositionInElement(position, element)) {
        setState(() {
          _selectedElementId = element.id;
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
      final dx = position.dx - element.x;
      final dy = position.dy - element.y;
      return (dx * dx + dy * dy) <= (element.radius * element.radius);
    } else if (element is SquareElement) {
      final halfSize = element.size / 2;
      return position.dx >= element.x - halfSize &&
             position.dx <= element.x + halfSize &&
             position.dy >= element.y - halfSize &&
             position.dy <= element.y + halfSize;
    } else if (element is TriangleElement) {
      final halfSize = element.size / 2;
      return position.dx >= element.x - halfSize &&
             position.dx <= element.x + halfSize &&
             position.dy >= element.y - halfSize &&
             position.dy <= element.y + halfSize;
    } else if (element is TextElement || element is LabelElement) {
      final x = element is TextElement ? element.x : (element as LabelElement).x;
      final y = element is TextElement ? element.y : (element as LabelElement).y;
      return (position.dx - x).abs() < 50 && (position.dy - y).abs() < 50;
    }
    return false;
  }
  
  void _moveSelectedElement(Offset position) {
    setState(() {
      final element = _diagram.elements.firstWhere((e) => e.id == _selectedElementId);
      
      if (element is CircleElement) {
        element.x = position.dx;
        element.y = position.dy;
      } else if (element is SquareElement) {
        element.x = position.dx;
        element.y = position.dy;
      } else if (element is TriangleElement) {
        element.x = position.dx;
        element.y = position.dy;
      } else if (element is TextElement) {
        element.x = position.dx;
        element.y = position.dy;
      } else if (element is LabelElement) {
        element.x = position.dx;
        element.y = position.dy;
      }
    });
  }
  
  void _addShape() {
    if (_drawStart == null || _drawCurrent == null) return;
    
    final id = const Uuid().v4();
    
    setState(() {
      switch (_selectedTool) {
        case DrawingTool.circle:
          final dx = _drawCurrent!.dx - _drawStart!.dx;
          final dy = _drawCurrent!.dy - _drawStart!.dy;
          final radius = (dx * dx + dy * dy).sqrt();
          _diagram.elements.add(CircleElement(
            id: id,
            x: _drawStart!.dx,
            y: _drawStart!.dy,
            radius: radius.clamp(10, 100),
            color: _selectedColor.value,
          ));
          break;
          
        case DrawingTool.square:
          final size = (_drawCurrent! - _drawStart!).distance.clamp(20, 100);
          _diagram.elements.add(SquareElement(
            id: id,
            x: _drawStart!.dx,
            y: _drawStart!.dy,
            size: size,
            color: _selectedColor.value,
          ));
          break;
          
        case DrawingTool.triangle:
          final size = (_drawCurrent! - _drawStart!).distance.clamp(20, 100);
          _diagram.elements.add(TriangleElement(
            id: id,
            x: _drawStart!.dx,
            y: _drawStart!.dy,
            size: size,
            color: _selectedColor.value,
          ));
          break;
          
        case DrawingTool.line:
          _diagram.elements.add(LineElement(
            id: id,
            x1: _drawStart!.dx,
            y1: _drawStart!.dy,
            x2: _drawCurrent!.dx,
            y2: _drawCurrent!.dy,
            color: _selectedColor.value,
            arrow: true,
          ));
          break;
          
        default:
          break;
      }
    });
  }
  
  void _addCurve() {
    if (_drawStart == null || _drawCurrent == null || _curveControl == null) return;
    
    final id = const Uuid().v4();
    
    setState(() {
      _diagram.elements.add(CurveElement(
        id: id,
        x1: _drawStart!.dx,
        y1: _drawStart!.dy,
        x2: _drawCurrent!.dx,
        y2: _drawCurrent!.dy,
        controlX: _curveControl!.dx,
        controlY: _curveControl!.dy,
        color: _selectedColor.value,
        arrow: true,
      ));
    });
  }
  
  void _addText(Offset position) {
    _showTextDialog((text) {
      final id = const Uuid().v4();
      setState(() {
        _diagram.elements.add(TextElement(
          id: id,
          x: position.dx,
          y: position.dy,
          text: text,
          color: _selectedColor.value,
        ));
      });
    });
  }
  
  void _addLabel(Offset position) {
    _showTextDialog((text) {
      final id = const Uuid().v4();
      setState(() {
        _diagram.elements.add(LabelElement(
          id: id,
          x: position.dx,
          y: position.dy,
          text: text,
          color: Colors.white.value,
          backgroundColor: _selectedColor.value,
        ));
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
  }
  
  void _saveDiagram() {
    Navigator.pop(context, _diagram);
  }
}
