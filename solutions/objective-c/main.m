#import <Foundation/Foundation.h>

int parseTemp(const char *buf, long start, long end) {
    long i = start;
    int neg = 0;
    if (buf[i] == '-') { neg = 1; i++; }
    int v = 0;
    while (buf[i] != '.') { v = v * 10 + (buf[i] - '0'); i++; }
    i++;
    int tenths = v * 10 + (buf[i] - '0');
    return neg ? -tenths : tenths;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        NSData *data = [NSData dataWithContentsOfFile:@"../../data/measurements.txt"];
        NSMutableDictionary *map = [NSMutableDictionary dictionary];
        const char *raw = data.bytes;
        NSUInteger n = data.length;
        NSUInteger i = 0;
        while (i < n) {
            NSUInteger semi = i;
            while (raw[semi] != ';') semi++;
            NSString *name = [[NSString alloc] initWithBytes:raw + i length:semi - i encoding:NSUTF8StringEncoding];
            long j = semi + 1;
            NSUInteger nl = j;
            while (nl < n && raw[nl] != '\n') nl++;
            int t = parseTemp(raw, j, nl);
            i = nl + 1;
            NSMutableArray *e = map[name];
            if (e) {
                if (t < [e[0] intValue]) e[0] = @(t);
                if (t > [e[1] intValue]) e[1] = @(t);
                e[2] = @([e[2] longLongValue] + t);
                e[3] = @([e[3] longLongValue] + 1);
            } else {
                map[name] = [@[@(t), @(t), @(t), @(1)] mutableCopy];
            }
        }
        NSArray *sorted = [[map allKeys] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            return [(NSString *)a compare:(NSString *)b options:NSLiteralSearch];
        }];
        for (NSString *name in sorted) {
            NSArray *e = map[name];
            printf("%s\t%d\t%d\t%lld\t%lld\n", name.UTF8String,
                   [e[0] intValue], [e[1] intValue],
                   [e[2] longLongValue], [e[3] longLongValue]);
        }
    }
    return 0;
}