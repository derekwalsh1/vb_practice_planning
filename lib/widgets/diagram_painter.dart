import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/diagram.dart';

class DiagramPainter extends CustomPainter {
  final Diagram diagram;
  final String? selectedElementId;
  final bool showCourt;
  
  DiagramPainter({
    required this.diagram,
    this.selectedElementId,
    this.showCourt = true,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (showCourt) {
      _drawCourt(canvas, size);
    }
    
    for (final element in diagram.elements) {
      _drawElement(canvas, element, element.id == selectedElementId);
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
    
    // Volleyball court proportions: 18m x 9m (2:1 ratio)
    final courtPadding = 40.0;
    final courtWidth = size.width - (courtPadding * 2);
    final courtHeight = diagram.courtType == CourtType.full 
        ? courtWidth / 2  // Full court is 2:1 ratio
        : courtWidth / 4; // Half court is 4:1 ratio
    
    final courtLeft = courtPadding;
    final courtTop = (size.height - courtHeight) / 2;
    final courtRight = courtLeft + courtWidth;
    final courtBottom = courtTop + courtHeight;
    
    // Outer boundary
    canvas.drawRect(
      Rect.fromLTRB(courtLeft, courtTop, courtRight, courtBottom),
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
    
    final attackLineDistance = courtHeight * 0.333; // 3m out of 9m
    
    if (diagram.courtType == CourtType.full) {
      // Top attack line
      canvas.drawLine(
        Offset(courtLeft, centerY - attackLineDistance),
        Offset(courtRight, centerY - attackLineDistance),
        attackLinePaint,
      );
      // Bottom attack line
      canvas.drawLine(
        Offset(courtLeft, centerY + attackLineDistance),
        Offset(courtRight, centerY + attackLineDistance),
        attackLinePaint,
      );
    } else {
      // Half court - only one attack line
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
    
    canvas.drawCircle(Offset(element.x, element.y), element.radius, paint);
    
    // Border
    final borderPaint = Paint()
      ..color = selected ? Colors.blue : Colors.black
      ..strokeWidth = selected ? 3.0 : 1.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(Offset(element.x, element.y), element.radius, borderPaint);
    
    // Label
    if (element.label != null && element.label!.isNotEmpty) {
      _drawCenteredText(canvas, element.label!, element.x, element.y, Colors.black, 16);
    }
  }
  
  void _drawSquare(Canvas canvas, SquareElement element, bool selected) {
    final paint = Paint()
      ..color = Color(element.color)
      ..style = PaintingStyle.fill;
    
    final rect = Rect.fromCenter(
      center: Offset(element.x, element.y),
      width: element.size,
      height: element.size,
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
      _drawCenteredText(canvas, element.label!, element.x, element.y, Colors.black, 16);
    }
  }
  
  void _drawTriangle(Canvas canvas, TriangleElement element, bool selected) {
    final paint = Paint()
      ..color = Color(element.color)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final halfSize = element.size / 2;
    
    // Equilateral triangle pointing up
    path.moveTo(element.x, element.y - halfSize); // Top
    path.lineTo(element.x - halfSize, element.y + halfSize); // Bottom left
    path.lineTo(element.x + halfSize, element.y + halfSize); // Bottom right
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
      _drawCenteredText(canvas, element.label!, element.x, element.y, Colors.black, 16);
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
    
    canvas.drawLine(
      Offset(element.x1, element.y1),
      Offset(element.x2, element.y2),
      paint,
    );
    
    // Draw arrow if needed
    if (element.arrow) {
      _drawArrowHead(canvas, element.x1, element.y1, element.x2, element.y2, 
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
    
    final path = Path();
    path.moveTo(element.x1, element.y1);
    path.quadraticBezierTo(
      element.controlX,
      element.controlY,
      element.x2,
      element.y2,
    );
    
    canvas.drawPath(path, paint);
    
    // Draw arrow if needed
    if (element.arrow) {
      // Calculate tangent at end point for arrow direction
      final t = 0.99; // Just before the end
      final x = math.pow(1 - t, 2) * element.x1 + 
                2 * (1 - t) * t * element.controlX + 
                math.pow(t, 2) * element.x2;
      final y = math.pow(1 - t, 2) * element.y1 + 
                2 * (1 - t) * t * element.controlY + 
                math.pow(t, 2) * element.y2;
      
      _drawArrowHead(canvas, x.toDouble(), y.toDouble(), element.x2, element.y2,
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
    
    if (selected) {
      // Draw selection background
      final rect = Rect.fromLTWH(
        element.x - 2,
        element.y - 2,
        textPainter.width + 4,
        textPainter.height + 4,
      );
      canvas.drawRect(
        rect,
        Paint()..color = Colors.blue.withOpacity(0.2),
      );
    }
    
    textPainter.paint(canvas, Offset(element.x, element.y));
  }
  
  void _drawLabel(Canvas canvas, LabelElement element, bool selected) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: element.text,
        style: TextStyle(
          color: Color(element.color),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Background circle
    final padding = 8.0;
    final radius = math.max(textPainter.width, textPainter.height) / 2 + padding;
    
    canvas.drawCircle(
      Offset(element.x, element.y),
      radius,
      Paint()..color = Color(element.backgroundColor),
    );
    
    // Border
    canvas.drawCircle(
      Offset(element.x, element.y),
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
        element.x - textPainter.width / 2,
        element.y - textPainter.height / 2,
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
  
  @override
  bool shouldRepaint(DiagramPainter oldDelegate) {
    return diagram != oldDelegate.diagram ||
           selectedElementId != oldDelegate.selectedElementId;
  }
}
