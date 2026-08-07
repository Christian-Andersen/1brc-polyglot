BEGIN { FS = ";" }
{
    city = $1
    sub(/\./, "", $2)
    temp = $2 + 0
    if (!(city in mn)) {
        mn[city] = temp
        mx[city] = temp
        tot[city] = temp
        cnt[city] = 1
    } else {
        if (temp < mn[city]) mn[city] = temp
        if (temp > mx[city]) mx[city] = temp
        tot[city] += temp
        cnt[city] += 1
    }
}
END {
    n = 0
    for (c in mn) names[++n] = c
    n = asort(names)
    for (i = 1; i <= n; i++) {
        c = names[i]
        print c "\t" mn[c] "\t" mx[c] "\t" tot[c] "\t" cnt[c]
    }
}
