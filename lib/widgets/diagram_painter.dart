import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/diagram.dart';

class DiagramPainter extends CustomPainter {
  final Diagram diagram;
  final String? selectedElementId;
  final bool showCourt;
  final Offset? drawStart;
  final Offset? drawCurrent;
  final Offset? curveControl;
  final String? drawingToolName;
  final Color drawingColor;
  
  // Court bounds in canvas coordinates (calculated during paint)
  late double courtLeft;
  late double courtTop;
  late double courtRight;
  late double courtBottom;
  late double courtWidth;
  late double courtHeight;
  
  DiagramPainter({
    required this.diagram,
    this.selectedElementId,
    this.showCourt = true,
    this.drawStart,
    this.drawCurrent,
    this.curveControl,
    this.drawingToolName,
    this.drawingColor = Colors.blue,
  });
  
  // Convert normalized court coordinates (0-1) to canvas coordinates
  double toCanvasX(double normalizedX) => courtLeft + (normalizedX * courtWidth);
  double toCanvasY(double normalizedY) => courtTop + (normalizedY * courtHeight);
  double toCanvasSize(double normalizedSize) => normalizedSize * courtWidth;
  
  // Convert canvas coordinates to normalized court coordinates (0-1)
  double toNormalizedX(double canvasX) => (canvasX - courtLeft) / courtWidth;
  double toNormalizedY(double canvasY) => (canvasY - courtTop) / courtHeight;
  double toNormalizedSize(double canvasSize) => canvasSize / courtWidth;
  
  @override
  void paint(Canvas canvas, Size size) {
    if (showCourt) {
      _drawCourt(canvas, size);
    }
    
    for (final element in diagram.elements) {
      _drawElement(canvas, element, element.id == selectedElementId);
    }
    
    // Draw preview while drawing
    if (drawStart != null && drawCurrent != null && drawingToolName != null) {
      _drawPreview(canvas);
    }
  }
  
  void _drawCourt(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Court lines
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    // Volleyball court proportions: 18m x 9m (width:height = 1:2 ratio)
    // Use 15% margin on all sides for off-court space
    final marginPercent = 0.15;
    final horizontalMargin = size.width * marginPercent;
    final verticalMargin = size.height * marginPercent;
    final availableWidth = size.width - (horizontalMargin * 2);
    final availableHeight = size.height - (verticalMargin * 2);
    
    // Calculate court dimensions respecting both bounds and maintaining aspect ratio
    double courtWidth;
    double courtHeight;
    
    if (diagram.courtType == CourtType.full) {
      // Full court is 1:2 ratio (width:height)
      // Check which dimension is the limiting factor
      if (availableWidth * 2 <= availableHeight) {
        // Width is the constraint
        courtWidth = availableWidth;
        courtHeight = courtWidth * 2;
      } else {
        // Height is the constraint
        courtHeight = availableHeight;
        courtWidth = courtHeight / 2;
      }
    } else {
      // Half court is 1:1 ratio (width:height)
      final minDimension = availableWidth < availableHeight ? availableWidth : availableHeight;
      courtWidth = minDimension;
      courtHeight = minDimension;
    }
    
    // Store court bounds for coordinate transformation
    this.courtLeft = (size.width - courtWidth) / 2;
    this.courtTop = (size.height - courtHeight) / 2;
    this.courtWidth = courtWidth;
    this.courtHeight = courtHeight;
    this.courtRight = this.courtLeft + courtWidth;
    this.courtBottom = this.courtTop + courtHeight;
    
    // Outer boundary
    canvas.drawRect(
      Rect.fromLTRB(this.courtLeft, this.courtTop, this.courtRight, this.courtBottom),
      linePaint,
    );
    
    // Center line (net)
    final centerY = diagram.courtType == CourtType.full
        ? courtTop + (courtHeight / 2)
        : courtTop;
    
    final netPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0;
    
    canvas.drawLine(
      Offset(courtLeft, centerY),
      Offset(courtRight, centerY),
      netPaint,
    );
    
    // Attack lines (3m from center on each side)
    final attackLinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    
    if (diagram.courtType == CourtType.full) {
      // For full court: attack line is 3m from center (3m out of 9m half = 1/3 of half court)
      final halfCourtHeight = courtHeight / 2;
      final attackLineDistance = halfCourtHeight / 3; // 3m out of 9m
      
      // Top attack line (3m from center toward top)
      canvas.drawLine(
        Offset(courtLeft, centerY - attackLineDistance),
        Offset(courtRight, centerY - attackLineDistance),
        attackLinePaint,
      );
      // Bottom attack line (3m from center toward bottom)
      canvas.drawLine(
        Offset(courtLeft, centerY + attackLineDistance),
        Offset(courtRight, centerY + attackLineDistance),
        attackLinePaint,
      );
    } else {
      // Half court - only one attack line (3m from net)
      final attackLineDistance = courtHeight / 3; // 3m out of 9m
      canvas.drawLine(
        Offset(courtLeft, centerY + attackLineDistance),
        Offset(courtRight, centerY + attackLineDistance),
        attackLinePaint,
      );
    }
  }
  
  void _drawElement(Canvas canvas, DiagramElement element, bool selected) {
    if (element is CircleElement) {
      _drawCircle(canvas, element, selected);
    } else if (element is SquareElement) {
      _drawSquare(canvas, element, selected);
    } else if (element is TriangleElement) {
      _drawTriangle(canvas, element, selected);
    } else if (element is LineElement) {
      _drawLine(canvas, element, selected);
    } else if (element is CurveElement) {
      _drawCurve(canvas, element, selected);
    } else if (element is TextElement) {
      _drawText(canvas, element, selected);
    } else if (element is LabelElement) {
      _drawLabel(canvas, element, selected);
    }
  }
  
  void _drawCircle(Canvas canvas, CircleElement element, bool selected) {
    final paint = Paint()
      ..color = Color(element.color)
      ..style = PaintingStyle.fill;
    
    final x = toCanvasX(element.x);
    final y = toCanvasY(element.y);
    final radius = toCanvasSize(element.radius);
    
    canvas.drawCircle(Offset(x, y), radius, paint);
    
    // Border
    final borderPaint = Paint()
      ..color = selected ? Colors.blue : Colors.black
      ..strokeWidth = selected ? 3.0 : 1.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(Offset(x, y), radius, borderPaint);
    
    // Label
    if (element.label != null && element.label!.isNotEmpty) {
      _drawCenteredText(canvas, element.label!, x, y, Colors.black, 16);
    }
  }
  
  void _drawSquare(Canvas canvas, SquareElement element, bool selected) {
    final paint = Paint()
      ..color = Color(element.color)
      ..style = PaintingStyle.fill;
    
    final x = toCanvasX(element.x);
    final y = toCanvasY(element.y);
    final size = toCanvasSize(element.size);
    
    final rect = Rect.fromCenter(
      center: Offset(x, y),
      width: size,
      height: size,
    );
    
    canvas.drawRect(rect, paint);
    
    // Border
    final borderPaint = Paint()
      ..color = selected ? Colors.blue : Colors.black
      ..strokeWidth = selected ? 3.0 : 1.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(rect, borderPaint);
    
    // Label
    if (element.label != null && element.label!.isNotEmpty) {
      _drawCenteredText(canvas, element.label!, x, y, Colors.black, 16);
    }
  }
  
  void _drawTriangle(Canvas canvas, TriangleElement element, bool selected) {
    final paint = Paint()
      ..color = Color(element.color)
      ..style = PaintingStyle.fill;
    
    final x = toCanvasX(element.x);
    final y = toCanvasY(element.y);
    final size = toCanvasSize(element.size);
    final halfSize = size / 2;
    
    final path = Path();
    // Equilateral triangle pointing up
    path.moveTo(x, y - halfSize); // Top
    path.lineTo(x - halfSize, y + halfSize); // Bottom left
    path.lineTo(x + halfSize, y + halfSize); // Bottom right
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Border
    final borderPaint = Paint()
      ..color = selected ? Colors.blue : Colors.black
      ..strokeWidth = selected ? 3.0 : 1.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(path, borderPaint);
    
    // Label
    if (element.label != null && element.label!.isNotEmpty) {
      _drawCenteredText(canvas, element.label!, x, y, Colors.black, 16);
    }
  }
  
  void _drawLine(Canvas canvas, LineElement element, bool selected) {
    final paint = Paint()
      ..color = Color(element.color)
      ..strokeWidth = element.strokeWidth
      ..style = PaintingStyle.stroke;
    
    if (selected) {
      paint.color = Colors.blue;
      paint.strokeWidth = element.strokeWidth + 2;
    }
    
    final x1 = toCanvasX(element.x1);
    final y1 = toCanvasY(element.y1);
    final x2 = toCanvasX(element.x2);
    final y2 = toCanvasY(element.y2);
    
    canvas.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      paint,
    );
    
    // Draw arrow if needed
    if (element.arrow) {
      _drawArrowHead(canvas, x1, y1, x2, y2, 
                     paint.color, paint.strokeWidth);
    }
  }
  
  void _drawCurve(Canvas canvas, CurveElement element, bool selected) {
    final paint = Paint()
      ..color = Color(element.color)
      ..strokeWidth = element.strokeWidth
      ..style = PaintingStyle.stroke;
    
    if (selected) {
      paint.color = Colors.blue;
      paint.strokeWidth = element.strokeWidth + 2;
    }
    
    final x1 = toCanvasX(element.x1);
    final y1 = toCanvasY(element.y1);
    final x2 = toCanvasX(element.x2);
    final y2 = toCanvasY(element.y2);
    final controlX = toCanvasX(element.controlX);
    final controlY = toCanvasY(element.controlY);
    
    final path = Path();
    path.moveTo(x1, y1);
    path.quadraticBezierTo(
      controlX,
      controlY,
      x2,
      y2,
    );
    
    canvas.drawPath(path, paint);
    
    // Draw arrow if needed
    if (element.arrow) {
      // Calculate tangent at end point for arrow direction
      final t = 0.99; // Just before the end
      final x = math.pow(1 - t, 2) * x1 + 
                2 * (1 - t) * t * controlX + 
                math.pow(t, 2) * x2;
      final y = math.pow(1 - t, 2) * y1 + 
                2 * (1 - t) * t * controlY + 
                math.pow(t, 2) * y2;
      
      _drawArrowHead(canvas, x.toDouble(), y.toDouble(), x2, y2,
                     paint.color, paint.strokeWidth);
    }
  }
  
  void _drawArrowHead(Canvas canvas, double x1, double y1, double x2, double y2,
                      Color color, double strokeWidth) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final angle = math.atan2(dy, dx);
    
    final arrowSize = 12.0;
    final arrowAngle = math.pi / 6; // 30 degrees
    
    final path = Path();
    path.moveTo(x2, y2);
    path.lineTo(
      x2 - arrowSize * math.cos(angle - arrowAngle),
      y2 - arrowSize * math.sin(angle - arrowAngle),
    );
    path.moveTo(x2, y2);
    path.lineTo(
      x2 - arrowSize * math.cos(angle + arrowAngle),
      y2 - arrowSize * math.sin(angle + arrowAngle),
    );
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(path, paint);
  }
  
  void _drawText(Canvas canvas, TextElement element, bool selected) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: element.text,
        style: TextStyle(
          color: Color(element.color),
          fontSize: element.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final x = toCanvasX(element.x);
    final y = toCanvasY(element.y);
    
    if (selected) {
      // Draw selection background
      final rect = Rect.fromLTWH(
        x - 2,
        y - 2,
        textPainter.width + 4,
        textPainter.height + 4,
      );
      canvas.drawRect(
        rect,
        Paint()..color = Colors.blue.withOpacity(0.2),
      );
    }
    
    textPainter.paint(canvas, Offset(x, y));
  }
  
  void _drawLabel(Canvas canvas, LabelElement element, bool selected) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: element.text,
        style: TextStyle(
          color: Color(element.color),
          fontSize: element.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final x = toCanvasX(element.x);
    final y = toCanvasY(element.y);
    
    // Background circle
    final padding = 8.0;
    final radius = math.max(textPainter.width, textPainter.height) / 2 + padding;
    
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()..color = Color(element.backgroundColor),
    );
    
    // Border
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..color = selected ? Colors.blue : Colors.black
        ..strokeWidth = selected ? 3.0 : 2.0
        ..style = PaintingStyle.stroke,
    );
    
    // Text centered
    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      ),
    );
  }
  
  void _drawCenteredText(Canvas canvas, String text, double x, double y, 
                         Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }
  
  void _drawPreview(Canvas canvas) {
    if (drawStart == null || drawCurrent == null || drawingToolName == null) {
      return;
    }
    
    final paint = Paint()
      ..color = drawingColor?.withOpacity(0.5) ?? Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final startX = toCanvasX(drawStart!.dx);
    final startY = toCanvasY(drawStart!.dy);
    final currentX = toCanvasX(drawCurrent!.dx);
    final currentY = toCanvasY(drawCurrent!.dy);
    
    switch (drawingToolName) {
      case 'circle':
        final dx = currentX - startX;
        final dy = currentY - startY;
        final radius = math.sqrt(dx * dx + dy * dy);
        canvas.drawCircle(Offset(startX, startY), radius, paint);
        break;
        
      case 'square':
        final rect = Rect.fromPoints(
          Offset(startX, startY),
          Offset(currentX, currentY),
        );
        canvas.drawRect(rect, paint);
        break;
        
      case 'triangle':
        final path = Path();
        final midX = (startX + currentX) / 2;
        path.moveTo(midX, startY);
        path.lineTo(currentX, currentY);
        path.lineTo(startX, currentY);
        path.close();
        canvas.drawPath(path, paint);
        break;
        
      case 'line':
        canvas.drawLine(
          Offset(startX, startY),
          Offset(currentX, currentY),
          paint..strokeWidth = 3.0,
        );
        break;
        
      case 'curve':
        if (curveControl != null) {
          final controlX = toCanvasX(curveControl!.dx);
          final controlY = toCanvasY(curveControl!.dy);
          final path = Path();
          path.moveTo(startX, startY);
          path.quadraticBezierTo(controlX, controlY, currentX, currentY);
          canvas.drawPath(path, paint..strokeWidth = 3.0);
        }
        break;
    }
  }
  
  @override
  bool shouldRepaint(DiagramPainter oldDelegate) {
    return diagram != oldDelegate.diagram ||
           selectedElementId != oldDelegate.selectedElementId ||
           drawStart != oldDelegate.drawStart ||
           drawCurrent != oldDelegate.drawCurrent ||
           curveControl != oldDelegate.curveControl ||
           drawingToolName != oldDelegate.drawingToolName;
  }
}
