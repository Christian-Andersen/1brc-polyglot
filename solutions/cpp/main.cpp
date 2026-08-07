#include <algorithm>
#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <unordered_map>

struct Stats {
    int min;
    int max;
    long long total;
    long long count;
};

int main() {
    std::unordered_map<std::string, Stats> data;
    std::ifstream file("../../data/measurements.txt");
    std::string line;
    while (std::getline(file, line)) {
        auto semi = line.find(';');
        std::string city = line.substr(0, semi);
        std::string temp = line.substr(semi + 1);
        temp.erase(std::remove(temp.begin(), temp.end(), '.'), temp.end());
        long long value = std::stoll(temp);
        auto it = data.find(city);
        if (it == data.end()) {
            data.emplace(city, Stats{(int)value, (int)value, value, 1});
        } else {
            it->second.min = std::min(it->second.min, (int)value);
            it->second.max = std::max(it->second.max, (int)value);
            it->second.total += value;
            it->second.count++;
        }
    }

    std::map<std::string, Stats> sorted(data.begin(), data.end());
    for (const auto& [city, s] : sorted)
        std::cout << city << '\t' << s.min << '\t' << s.max << '\t'
                  << s.total << '\t' << s.count << '\n';
}
