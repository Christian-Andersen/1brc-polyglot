#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TABLE_SIZE 65536
#define MAX_CITY 64

typedef struct {
    char city[MAX_CITY];
    int min;
    int max;
    long total;
    long count;
    int used;
} Entry;

static Entry table[TABLE_SIZE];

static unsigned int hash_city(const char *s) {
    unsigned int h = 0;
    while (*s)
        h = (h * 31u + (unsigned char)*s++) & (TABLE_SIZE - 1);
    return h;
}

static int cmp_entry(const void *a, const void *b) {
    const Entry *ea = *(const Entry *const *)a;
    const Entry *eb = *(const Entry *const *)b;
    return strcmp(ea->city, eb->city);
}

int main(void) {
    FILE *f = fopen("../../data/measurements.txt", "r");
    if (!f) {
        perror("fopen");
        return 1;
    }

    char line[256];
    while (fgets(line, sizeof line, f)) {
        char *semi = strchr(line, ';');
        if (!semi) continue;
        *semi = '\0';

        char *temp = semi + 1;
        size_t len = strlen(temp);
        if (len && temp[len - 1] == '\n') temp[len - 1] = '\0';

        char digits[64];
        size_t j = 0;
        for (size_t i = 0; temp[i]; i++)
            if (temp[i] != '.') digits[j++] = temp[i];
        digits[j] = '\0';
        long value = atol(digits);

        unsigned int idx = hash_city(line) & (TABLE_SIZE - 1);
        while (table[idx].used && strcmp(table[idx].city, line) != 0)
            idx = (idx + 1) & (TABLE_SIZE - 1);

        if (!table[idx].used) {
            table[idx].used = 1;
            strncpy(table[idx].city, line, MAX_CITY - 1);
            table[idx].min = (int)value;
            table[idx].max = (int)value;
            table[idx].total = value;
            table[idx].count = 1;
        } else {
            if (value < table[idx].min) table[idx].min = (int)value;
            if (value > table[idx].max) table[idx].max = (int)value;
            table[idx].total += value;
            table[idx].count++;
        }
    }
    fclose(f);

    const Entry *entries[TABLE_SIZE];
    long n = 0;
    for (long i = 0; i < TABLE_SIZE; i++)
        if (table[i].used) entries[n++] = &table[i];

    qsort(entries, n, sizeof *entries, cmp_entry);

    for (long i = 0; i < n; i++)
        printf("%s\t%d\t%d\t%ld\t%ld\n",
               entries[i]->city, entries[i]->min, entries[i]->max,
               entries[i]->total, entries[i]->count);
    return 0;
}
