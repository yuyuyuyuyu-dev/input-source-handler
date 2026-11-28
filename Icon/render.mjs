import { readFile, writeFile } from "node:fs/promises";
import { Resvg } from "@resvg/resvg-js";

const source = new URL("./AppIcon.svg", import.meta.url);
const iconSet = new URL(
	"../InputSourceHandler/Assets.xcassets/AppIcon.appiconset/",
	import.meta.url,
);

const svg = await readFile(source);
const contents = JSON.parse(
	await readFile(new URL("Contents.json", iconSet), "utf8"),
);

for (const image of contents.images) {
	const points = Number.parseInt(image.size, 10);
	const scale = Number.parseInt(image.scale, 10);
	const pixels = points * scale;
	const filename = `icon_${image.size}@${image.scale}.png`;
	const png = new Resvg(svg, { fitTo: { mode: "width", value: pixels } })
		.render()
		.asPng();
	await writeFile(new URL(filename, iconSet), png);
	image.filename = filename;
}

await writeFile(
	new URL("Contents.json", iconSet),
	`${JSON.stringify(contents, null, "\t")}\n`,
);
