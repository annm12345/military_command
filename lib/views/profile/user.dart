class User {
  final String name;
  final String rank;
  final String bc;
  final String unit;
  final String email;
  final String mobile;
  final String command;

  User({
    required this.name,
    required this.rank,
    required this.bc,
    required this.unit,
    required this.email,
    required this.mobile,
    required this.command,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      rank: json['rank'],
      bc: json['bc'],
      unit: json['unit'],
      email: json['email'],
      mobile: json['mobile'],
      command: json['command'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rank': rank,
      'bc': bc,
      'unit': unit,
      'email': email,
      'mobile': mobile,
      'command': command,
    };
  }
}
