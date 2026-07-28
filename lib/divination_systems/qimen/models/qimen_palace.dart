class QimenPalace {
  const QimenPalace({
    required this.number,
    required this.name,
    required this.trigram,
    required this.direction,
    required this.element,
    required this.branches,
    required this.earthStem,
    this.hostedEarthStem,
    required this.heavenStem,
    this.hostedHeavenStem,
    required this.star,
    this.hostedStar,
    this.door,
    this.deity,
    this.hiddenStem,
    this.voidBranches = const <String>[],
    this.isHorse = false,
    this.marks = const <String>[],
  });

  final int number;
  final String name;
  final String trigram;
  final String direction;
  final String element;
  final List<String> branches;
  final String earthStem;
  final String? hostedEarthStem;
  final String heavenStem;
  final String? hostedHeavenStem;
  final String star;
  final String? hostedStar;
  final String? door;
  final String? deity;
  final String? hiddenStem;
  final List<String> voidBranches;
  final bool isHorse;
  final List<String> marks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'number': number,
        'name': name,
        'trigram': trigram,
        'direction': direction,
        'element': element,
        'branches': branches,
        'earthStem': earthStem,
        'hostedEarthStem': hostedEarthStem,
        'heavenStem': heavenStem,
        'hostedHeavenStem': hostedHeavenStem,
        'star': star,
        'hostedStar': hostedStar,
        'door': door,
        'deity': deity,
        'hiddenStem': hiddenStem,
        'voidBranches': voidBranches,
        'isHorse': isHorse,
        'marks': marks,
      };

  factory QimenPalace.fromJson(Map<String, dynamic> json) => QimenPalace(
        number: json['number'] as int,
        name: json['name'] as String,
        trigram: json['trigram'] as String,
        direction: json['direction'] as String,
        element: json['element'] as String,
        branches: List<String>.from(json['branches'] as List),
        earthStem: json['earthStem'] as String,
        hostedEarthStem: json['hostedEarthStem'] as String?,
        heavenStem: json['heavenStem'] as String,
        hostedHeavenStem: json['hostedHeavenStem'] as String?,
        star: json['star'] as String,
        hostedStar: json['hostedStar'] as String?,
        door: json['door'] as String?,
        deity: json['deity'] as String?,
        hiddenStem: json['hiddenStem'] as String?,
        voidBranches: List<String>.from(json['voidBranches'] as List),
        isHorse: json['isHorse'] as bool,
        marks: List<String>.from(json['marks'] as List),
      );
}
