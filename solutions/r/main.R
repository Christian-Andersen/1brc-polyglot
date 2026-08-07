con <- file("../../data/measurements.txt", "r")
stats <- new.env(hash = TRUE, parent = emptyenv())
repeat {
    lines <- readLines(con, n = 100000)
    if (length(lines) == 0) break
    for (line in lines) {
        parts <- strsplit(line, ";", fixed = TRUE)[[1]]
        city <- parts[1]
        temp <- as.integer(gsub(".", "", parts[2], fixed = TRUE))
        if (exists(city, envir = stats, inherits = FALSE)) {
            s <- get(city, envir = stats, inherits = FALSE)
            s[1] <- min(s[1], temp)
            s[2] <- max(s[2], temp)
            s[3] <- s[3] + temp
            s[4] <- s[4] + 1
            assign(city, s, envir = stats)
        } else {
            assign(city, c(temp, temp, temp, 1L), envir = stats)
        }
    }
}
close(con)

for (city in sort(enc2utf8(ls(stats, all.names = TRUE)), method = "radix")) {
    s <- get(city, envir = stats, inherits = FALSE)
    cat(paste(c(city, s[1], s[2], s[3], s[4]), collapse = "\t"), "\n", sep = "")
}
