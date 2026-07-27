/// 标签吉凶极性（跨术数系统共享）
enum Polarity {
  ji('吉'),
  xiong('凶'),
  neutral('中性');

  const Polarity(this.name);
  final String name;
}
