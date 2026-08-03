import java.io.BufferedReader
import java.io.FileReader
import java.util.HashMap

data class Stats(var min: Int, var max: Int, var total: Int, var count: Int)

fun main() {
    val map = HashMap<String, Stats>()
    BufferedReader(FileReader("../../data/measurements.txt")).use { br ->
        var line = br.readLine()
        while (line != null) {
            val idx = line.indexOf(';')
            val city = line.substring(0, idx)
            val temp = line.substring(idx + 1).replace(".", "").toInt()
            map.compute(city) { _, s ->
                if (s == null) Stats(temp, temp, temp, 1)
                else Stats(minOf(s.min, temp), maxOf(s.max, temp), s.total + temp, s.count + 1)
            }
            line = br.readLine()
        }
    }
    for (city in map.keys.sorted()) {
        val stats = map[city]!!
        println("$city\t${stats.min}\t${stats.max}\t${stats.total}\t${stats.count}")
    }
}
