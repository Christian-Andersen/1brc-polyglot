import java.util.TreeMap;
import java.util.HashMap;
import java.util.Map;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.stream.Stream;

class Main {
    record Stats(int min, int max, int total, int count) {}
    public static void main(String[] args) throws IOException {
        Map<String, Stats> map = new HashMap<>();
        BufferedReader br = new BufferedReader(new FileReader("../../data/measurements.txt"));
        String line;
        while ((line = br.readLine()) != null) {
            int semicolonIndex = line.indexOf(";");
            String city = line.substring(0, semicolonIndex);
            int temp = Integer.parseInt(line.substring(semicolonIndex + 1).replace(".", ""));
            map.compute(city, (key, stats) -> {
                if (stats == null) {
                    return new Stats(temp, temp, temp, 1);
                } else {
                    return new Stats(
                        Math.min(stats.min, temp),
                        Math.max(stats.max, temp),
                        stats.total + temp,
                        stats.count + 1
                    );
                }
            });
        }
        map.entrySet().stream()
       .sorted(Map.Entry.comparingByKey())
       .forEach(entry -> System.out.println(entry.getKey() + "\t" + entry.getValue().min + "\t" + entry.getValue().max + "\t" + entry.getValue().total + "\t" + entry.getValue().count));
    }
}
