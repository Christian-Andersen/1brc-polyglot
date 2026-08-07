fh = fopen("../../data/measurements.txt", "r");
C = textscan(fh, "%s %s", "Delimiter", ";", "EndOfLine", "\n");
fclose(fh);
cities = C{1};
vals = str2double(strrep(C{2}, ".", ""));
[u, ~, ic] = unique(cities);
mn = accumarray(ic, vals, [], @min);
mx = accumarray(ic, vals, [], @max);
tot = accumarray(ic, vals, [], @sum);
cnt = accumarray(ic, 1);
for k = 1:numel(u)
    printf("%s\t%d\t%d\t%d\t%d\n", u{k}, mn(k), mx(k), tot(k), cnt(k));
end
