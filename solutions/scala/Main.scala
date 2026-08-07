import scala.collection.mutable

object Main:
  def main(args: Array[String]): Unit =
    val data = mutable.HashMap.empty[String, (Int, Int, Long, Long)]
    val source = scala.io.Source.fromFile("../../data/measurements.txt")
    for line <- source.getLines() do
      val semi = line.indexOf(';')
      val city = line.substring(0, semi)
      val temp = parseTemp(line, semi + 1)
      data.get(city) match
        case Some((mn, mx, tot, cnt)) =>
          data.update(city, (math.min(mn, temp), math.max(mx, temp), tot + temp, cnt + 1))
        case None =>
          data.update(city, (temp, temp, temp.toLong, 1L))
    source.close()
    for (city, (mn, mx, tot, cnt)) <- data.toSeq.sortBy(_._1) do
      println(s"$city\t$mn\t$mx\t$tot\t$cnt")

  private def parseTemp(line: String, start: Int): Int =
    var i = start
    var neg = false
    if line.charAt(i) == '-' then
      neg = true
      i += 1
    var v = 0
    while line.charAt(i) != '.' do
      v = v * 10 + (line.charAt(i) - '0')
      i += 1
    i += 1
    val tenths = v * 10 + (line.charAt(i) - '0')
    if neg then -tenths else tenths
