enum CourtType { full, half }

enum ElementType { circle, square, triangle, line, curve, text, label }

abstract class DiagramElement {
  final String id;
  final ElementType type;
  
  DiagramElement({required this.id, required this.type});
  
  Map<String, dynamic> toJson();
  
  factory DiagramElement.fromJson(Map<String, dynamic> json) {
    final type = ElementType.values.firstWhere(
      (e) => e.toString() == json['type'],
    );
    
    switch (type) {
      case ElementType.circle:
        return CircleElement.fromJson(json);
      case ElementType.square:
        return SquareElement.fromJson(json);
      case ElementType.triangle:
        return TriangleElement.fromJson(json);
      case ElementType.line:
        return LineElement.fromJson(json);
      case ElementType.curve:
        return CurveElement.fromJson(json);
      case ElementType.text:
        return TextElement.fromJson(json);
      case ElementType.label:
        return LabelElement.fromJson(json);
    }
  }
}

class CircleElement extends DiagramElement {
  double x;
  double y;
  double radius;
  int color; // Stored as ARGB int
  String? label;
  
  CircleElement({
    required String id,
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    this.label,
  }) : super(id: id, type: ElementType.circle);
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'x': x,
    'y': y,
    'radius': radius,
    'color': color,
    if (label != null) 'label': label,
  };
  
  factory CircleElement.fromJson(Map<String, dynamic> json) => CircleElement(
    id: json['id'],
    x: json['x'],
    y: json['y'],
    radius: json['radius'],
    color: json['color'],
    label: json['label'],
  );
}

class SquareElement extends DiagramElement {
  double x;
  double y;
  double size;
  int color;
  String? label;
  
  SquareElement({
    required String id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    this.label,
  }) : super(id: id, type: ElementType.square);
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'x': x,
    'y': y,
    'size': size,
    'color': color,
    if (label != null) 'label': label,
  };
  
  factory SquareElement.fromJson(Map<String, dynamic> json) => SquareElement(
    id: json['id'],
    x: json['x'],
    y: json['y'],
    size: json['size'],
    color: json['color'],
    label: json['label'],
  );
}

class TriangleElement extends DiagramElement {
  double x;
  double y;
  double size;
  int color;
  String? label;
  
  TriangleElement({
    required String id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    this.label,
  }) : super(id: id, type: ElementType.triangle);
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'x': x,
    'y': y,
    'size': size,
    'color': color,
    if (label != null) 'label': label,
  };
  
  factory TriangleElement.fromJson(Map<String, dynamic> json) => TriangleElement(
    id: json['id'],
    x: json['x'],
    y: json['y'],
    size: json['size'],
    color: json['color'],
    label: json['label'],
  );
}

class LineElement extends DiagramElement {
  double x1;
  double y1;
  double x2;
  double y2;
  int color;
  double strokeWidth;
  bool arrow;
  
  LineElement({
    required String id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.color,
    this.strokeWidth = 2.0,
    this.arrow = false,
  }) : super(id: id, type: ElementType.line);
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'x1': x1,
    'y1': y1,
    'x2': x2,
    'y2': y2,
    'color': color,
    'strokeWidth': strokeWidth,
    'arrow': arrow,
  };
  
  factory LineElement.fromJson(Map<String, dynamic> json) => LineElement(
    id: json['id'],
    x1: json['x1'],
    y1: json['y1'],
    x2: json['x2'],
    y2: json['y2'],
    color: json['color'],
    strokeWidth: json['strokeWidth'] ?? 2.0,
    arrow: json['arrow'] ?? false,
  );
}

class CurveElement extends DiagramElement {
  double x1;
  double y1;
  double x2;
  double y2;
  double controlX;
  double controlY;
  int color;
  double strokeWidth;
  bool arrow;
  
  CurveElement({
    required String id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.controlX,
    required this.controlY,
    required this.color,
    this.strokeWidth = 2.0,
    this.arrow = false,
  }) : super(id: id, type: ElementType.curve);
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'x1': x1,
    'y1': y1,
    'x2': x2,
    'y2': y2,
    'controlX': controlX,
    'controlY': controlY,
    'color': color,
    'strokeWidth': strokeWidth,
    'arrow': arrow,
  };
  
  factory CurveElement.fromJson(Map<String, dynamic> json) => CurveElement(
    id: json['id'],
    x1: json['x1'],
    y1: json['y1'],
    x2: json['x2'],
    y2: json['y2'],
    controlX: json['controlX'],
    controlY: json['controlY'],
    color: json['color'],
    strokeWidth: json['strokeWidth'] ?? 2.0,
    arrow: json['arrow'] ?? false,
  );
}

class TextElement extends DiagramElement {
  double x;
  double y;
  String text;
  int color;
  double fontSize;
  
  TextElement({
    required String id,
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.fontSize = 14.0,
  }) : super(id: id, type: ElementType.text);
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'x': x,
    'y': y,
    'text': text,
    'color': color,
    'fontSize': fontSize,
  };
  
  factory TextElement.fromJson(Map<String, dynamic> json) => TextElement(
    id: json['id'],
    x: json['x'],
    y: json['y'],
    text: json['text'],
    color: json['color'],
    fontSize: json['fontSize'] ?? 14.0,
  );
}

class LabelElement extends DiagramElement {
  double x;
  double y;
  String text;
  int color;
  int backgroundColor;
  double fontSize;
  
  LabelElement({
    required String id,
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    required this.backgroundColor,
    this.fontSize = 14.0,
  }) : super(id: id, type: ElementType.label);
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'x': x,
    'y': y,
    'text': text,
    'color': color,
    'backgroundColor': backgroundColor,
    'fontSize': fontSize,
  };
  
  factory LabelElement.fromJson(Map<String, dynamic> json) => LabelElement(
    id: json['id'],
    x: json['x'],
    y: json['y'],
    text: json['text'],
    color: json['color'],
    backgroundColor: json['backgroundColor'],
    fontSize: json['fontSize'] ?? 14.0,
  );
}

class Diagram {
  CourtType courtType;
  List<DiagramElement> elements;
  
  Diagram({
    this.courtType = CourtType.full,
    List<DiagramElement>? elements,
  }) : elements = elements ?? [];
  
  Map<String, dynamic> toJson() => {
    'courtType': courtType.toString(),
    'elements': elements.map((e) => e.toJson()).toList(),
  };
  
  factory Diagram.fromJson(Map<String, dynamic> json) {
    final courtTypeStr = json['courtType'] as String;
    final courtType = CourtType.values.firstWhere(
      (e) => e.toString() == courtTypeStr,
      orElse: () => CourtType.full,
    );
    
    final elementsList = json['elements'] as List<dynamic>?;
    final elements = elementsList
        ?.map((e) => DiagramElement.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    
    return Diagram(
      courtType: courtType,
      elements: elements,
    );
  }
}
