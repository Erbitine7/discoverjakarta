class Area {
  final String id;
  final String name;
  final String color;

  const Area({
    required this.id,
    required this.name,
    required this.color,
  });
}

final List<Area> jakartaAreas = [
  Area(id: 'central', name: 'Central Jakarta', color: '#FC351C'),
  Area(id: 'north', name: 'North Jakarta', color: '#19AE5D'),
  Area(id: 'south', name: 'South Jakarta', color: '#1C5DDC'),
  Area(id: 'west', name: 'West Jakarta', color: '#FEB52B'),
  Area(id: 'east', name: 'East Jakarta', color: '#EB30A2'),
];