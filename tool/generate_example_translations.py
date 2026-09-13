import concurrent.futures
import argparse
import html
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "assets" / "data" / "vocab_seed.json"
OUTPUT = ROOT / "assets" / "data" / "example_translations_zh.json"


def translate(example, email=""):
    url = (
        "https://api.mymemory.translated.net/get?q="
        f"{urllib.parse.quote(example)}&langpair=en%7Czh-CN"
    )
    if email:
        url += f"&de={urllib.parse.quote(email)}"
    for attempt in range(3):
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                payload = json.loads(response.read())
            if payload.get("responseStatus") == 200:
                translated = html.unescape(
                    payload.get("responseData", {}).get("translatedText", "")
                ).strip()
                if translated and "MYMEMORY WARNING" not in translated:
                    return translated
        except Exception:
            if attempt < 2:
                time.sleep(1.5 * (attempt + 1))
    return ""


def main():
    parser = argparse.ArgumentParser(
        description="Generate local Chinese translations for example sentences."
    )
    parser.add_argument(
        "--kind",
        choices=("all", "word", "phrase"),
        default="all",
        help="Only translate one vocabulary kind.",
    )
    parser.add_argument(
        "--email",
        default="",
        help="Optional MyMemory email parameter for a higher request quota.",
    )
    args = parser.parse_args()

    with SEED.open(encoding="utf-8") as handle:
        seed = json.load(handle)
    translations = {}
    if OUTPUT.exists():
        with OUTPUT.open(encoding="utf-8") as handle:
            translations = json.load(handle)

    examples = list(
        dict.fromkeys(
            item["example"]
            for item in seed["items"]
            if item.get("example")
            and (args.kind == "all" or item.get("kind") == args.kind)
            and item["example"] not in translations
        )
    )
    print(f"Need translations: {len(examples)}")

    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        futures = {
            executor.submit(translate, example, args.email): example
            for example in examples
        }
        for index, future in enumerate(concurrent.futures.as_completed(futures), 1):
            example = futures[future]
            translation = future.result()
            if translation:
                translations[example] = translation
            print(f"[{index}/{len(examples)}] {len(translation) > 0}")
            if index % 25 == 0:
                OUTPUT.write_text(
                    json.dumps(translations, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )

    OUTPUT.write_text(
        json.dumps(translations, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Saved translations: {len(translations)}")


if __name__ == "__main__":
    main()
