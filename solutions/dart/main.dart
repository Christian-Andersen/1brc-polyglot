import 'dart:convert';
import 'dart:math';
import 'dart:io';

class Stats {
  int min;
  int max;
  int total;
  int count;
  Stats({
    required this.min,
    required this.max,
    required this.total,
    required this.count,
  });
}

void main() async {
  final Map<String, Stats> data = {};
  final file = File('../../data/measurements.txt');
  final lines = file.openRead().transform(utf8.decoder).transform(LineSplitter());
  await for (final line in lines) {
    final [city, tempStr] = line.split(';');
    final temp = int.parse(tempStr.replaceAll('.', ''));
    final stats = data[city];
    if (stats == null) {
      data[city] = Stats(
        min: temp,
        max: temp,
        total: temp,
        count: 1,
      );
    } else {
      stats.min = min(stats.min, temp);
      stats.max = max(stats.max, temp);
      stats.total += temp;
      stats.count += 1;
    }
  }
  final sortedCities = data.keys.toList()..sort();
  for (final city in sortedCities) {
    final stats = data[city]!;
    print('$city\t${stats.min}\t${stats.max}\t${stats.total}\t${stats.count}');
  }
}
