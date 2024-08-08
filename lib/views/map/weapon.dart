class Weapon {
  final String name;
  final double range; // in meters
  final String bulletFlightTime; // in seconds
  final String gunPower; // arbitrary unit
  final String longDistance; // in meters

  Weapon({
    required this.name,
    required this.range,
    required this.bulletFlightTime,
    required this.gunPower,
    required this.longDistance,
  });
}

final List<Weapon> weapons = [
  Weapon(
      name: 'MA7',
      range: 250,
      bulletFlightTime: '18.3',
      gunPower: '0',
      longDistance: '1427'),
  Weapon(
      name: 'MA7',
      range: 300,
      bulletFlightTime: '18.2',
      gunPower: '0',
      longDistance: '1390'),
  Weapon(
      name: 'MA7',
      range: 350,
      bulletFlightTime: '18',
      gunPower: '0',
      longDistance: '1353'),
  Weapon(
      name: 'MA7',
      range: 400,
      bulletFlightTime: '17.8',
      gunPower: '0',
      longDistance: '1313'),
  Weapon(
      name: 'MA7',
      range: 450,
      bulletFlightTime: '17.6',
      gunPower: '0',
      longDistance: '1272'),
  Weapon(
      name: 'MA7',
      range: 500,
      bulletFlightTime: '17.3/25.3',
      gunPower: '0/1',
      longDistance: '1228/1435'),
  Weapon(
      name: 'MA7',
      range: 550,
      bulletFlightTime: '17/25.2',
      gunPower: '0/1',
      longDistance: '1181/1418'),
  Weapon(
      name: 'MA7',
      range: 600,
      bulletFlightTime: '16.6/25.1',
      gunPower: '0/1',
      longDistance: '1129/1400'),
  Weapon(
      name: 'MA7',
      range: 650,
      bulletFlightTime: '16/25',
      gunPower: '0/1',
      longDistance: '1066/1382'),
  Weapon(
      name: 'MA7',
      range: 700,
      bulletFlightTime: '15.3/24.9',
      gunPower: '0/1',
      longDistance: '987/1364'),
  Weapon(
      name: 'MA7',
      range: 750,
      bulletFlightTime: '13.1/24.8',
      gunPower: '0/1',
      longDistance: '800/1346'),
  Weapon(
      name: 'MA7',
      range: 800,
      bulletFlightTime: '24.7/25.9',
      gunPower: '1/2',
      longDistance: '1327/1408'),
  Weapon(
      name: 'MA7',
      range: 850,
      bulletFlightTime: '24.6/25.8',
      gunPower: '1/2',
      longDistance: '1308/1395'),
  Weapon(
      name: 'MA7',
      range: 900,
      bulletFlightTime: '24.5/25.7',
      gunPower: '1/2',
      longDistance: '1289/1390'),
  Weapon(
      name: 'MA7',
      range: 950,
      bulletFlightTime: '24.3/25.6',
      gunPower: '1/2',
      longDistance: '1269/1378'),
  Weapon(
      name: 'MA7',
      range: 1000,
      bulletFlightTime: '24.2/25.5',
      gunPower: '1/2',
      longDistance: '1248/1365'),
  Weapon(
      name: 'MA7',
      range: 1050,
      bulletFlightTime: '24/25.4',
      gunPower: '1/2',
      longDistance: '1227/1359'),
  Weapon(
      name: 'MA7',
      range: 1100,
      bulletFlightTime: '23.8/25.3',
      gunPower: '1/2',
      longDistance: '1204/1340'),
  Weapon(
      name: 'MA7',
      range: 1150,
      bulletFlightTime: '23.5/25.2',
      gunPower: '1/2',
      longDistance: '1181/1327'),
  Weapon(
      name: 'MA7',
      range: 1200,
      bulletFlightTime: '23.3/25.1',
      gunPower: '1/2',
      longDistance: '1157/1313'),
  Weapon(
      name: 'MA7',
      range: 1250,
      bulletFlightTime: '23/25',
      gunPower: '1/2',
      longDistance: '1131/1300'),
  Weapon(
      name: 'MA7',
      range: 1300,
      bulletFlightTime: '22.6/24.9',
      gunPower: '1/2',
      longDistance: '1103/1286'),
  Weapon(
      name: 'MA7',
      range: 1350,
      bulletFlightTime: '22.3/24.8',
      gunPower: '1/2',
      longDistance: '1073/1272'),
  Weapon(
      name: 'MA7',
      range: 1400,
      bulletFlightTime: '21.9/24.7',
      gunPower: '1/2',
      longDistance: '1039/1258'),
  Weapon(
      name: 'MA7',
      range: 1450,
      bulletFlightTime: '21.3/24.6',
      gunPower: '1/2',
      longDistance: '1000/1243'),
  Weapon(
      name: 'MA8',
      range: 1450,
      bulletFlightTime: '21.3/24.6',
      gunPower: '1/2',
      longDistance: '1500/1243'),
  Weapon(
      name: 'MA7',
      range: 1500,
      bulletFlightTime: '20.6/24.4',
      gunPower: '1/2',
      longDistance: '952/1228'),
  Weapon(
      name: 'MA7',
      range: 1550,
      bulletFlightTime: '18.2/24.2',
      gunPower: '1/2',
      longDistance: '800/1213'),
  Weapon(
      name: 'MA7',
      range: 1600,
      bulletFlightTime: '24',
      gunPower: '2',
      longDistance: '1197'),
  Weapon(
      name: 'MA7',
      range: 1650,
      bulletFlightTime: '23.8',
      gunPower: '2',
      longDistance: '1181'),
  Weapon(
      name: 'MA7',
      range: 1700,
      bulletFlightTime: '23.6',
      gunPower: '2',
      longDistance: '1164'),
  Weapon(
      name: 'MA7',
      range: 1750,
      bulletFlightTime: '23.4',
      gunPower: '2',
      longDistance: '1146'),
  Weapon(
      name: 'MA7',
      range: 1800,
      bulletFlightTime: '23.2',
      gunPower: '2',
      longDistance: '1128'),
  Weapon(
      name: 'MA7',
      range: 1850,
      bulletFlightTime: '23',
      gunPower: '2',
      longDistance: '1108'),
  Weapon(
      name: 'MA7',
      range: 1900,
      bulletFlightTime: '22.7',
      gunPower: '2',
      longDistance: '1088'),
  Weapon(
      name: 'MA7',
      range: 1950,
      bulletFlightTime: '22.3',
      gunPower: '2',
      longDistance: '1066'),
  Weapon(
      name: 'MA7',
      range: 2000,
      bulletFlightTime: '21.9',
      gunPower: '2',
      longDistance: '1042'),
  Weapon(
      name: 'MA7',
      range: 2050,
      bulletFlightTime: '21.5',
      gunPower: '2',
      longDistance: '1016'),
  Weapon(
      name: 'MA7',
      range: 2100,
      bulletFlightTime: '19',
      gunPower: '2',
      longDistance: '987'),
  Weapon(
      name: 'MA7',
      range: 2150,
      bulletFlightTime: '18.6',
      gunPower: '2',
      longDistance: '952'),
  Weapon(
      name: 'MA7',
      range: 2200,
      bulletFlightTime: '37/44.1',
      gunPower: '3/4',
      longDistance: '1161/1251'),
];
