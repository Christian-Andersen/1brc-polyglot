import * as fs from "fs";
import * as readline from "readline";

const DATA_PATH = "../../data/measurements.txt";

type Stats = {
	min: number;
	max: number;
	total: number;
	count: number;
};

async function main(): Promise<void> {
	const fileStream = fs.createReadStream(DATA_PATH);
	const rl = readline.createInterface({
		input: fileStream,
		crlfDelay: Infinity,
	});
	const data: Map<string, Stats> = new Map();
	for await (const line of rl) {
		const [city, tempStr] = line.split(";");
		const temp = parseInt(tempStr.replace(".", ""));
		const oldStats = data.get(city);
		if (oldStats) {
			data.set(city, {
				min: Math.min(temp, oldStats.min),
				max: Math.max(temp, oldStats.max),
				total: oldStats.total + temp,
				count: oldStats.count + 1,
			});
		} else {
			data.set(city, { min: temp, max: temp, total: temp, count: 1 });
		}
	}
	for (const [city, stats] of [...data.entries()].sort((a, b) =>
		a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0,
	)) {
		console.log(`${city}\t${stats.min}\t${stats.max}\t${stats.total}\t${stats.count}`);
	}
}

main();
