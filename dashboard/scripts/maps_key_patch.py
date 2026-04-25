import argparse
import pathlib
import re
import sys

MAPS_SCRIPT_PATTERN = re.compile(
    r"https://maps\.googleapis\.com/maps/api/js\?key=[^\"'&]+(?:&loading=async)?"
)
PLACEHOLDER_KEY = "YOUR_GOOGLE_MAPS_API_KEY"


def replace_maps_script_url(index_path: pathlib.Path, key: str) -> bool:
    source = index_path.read_text(encoding="utf-8")
    replacement = f"https://maps.googleapis.com/maps/api/js?key={key}&loading=async"
    updated, count = MAPS_SCRIPT_PATTERN.subn(replacement, source, count=1)
    if count == 0:
        return False
    index_path.write_text(updated, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Patch Google Maps key in dashboard web/index.html"
    )
    parser.add_argument("mode", choices=["inject", "restore"])
    parser.add_argument("--key", help="Google Maps API key (required for inject mode)")
    args = parser.parse_args()

    if args.mode == "inject" and not args.key:
        print("[ERROR] --key is required for inject mode")
        return 2

    target_key = args.key if args.mode == "inject" else PLACEHOLDER_KEY
    index_path = pathlib.Path("web/index.html")
    if not index_path.exists():
        print("[ERROR] web/index.html not found")
        return 3

    if not replace_maps_script_url(index_path, target_key):
        print("[ERROR] Could not find Google Maps script URL in web/index.html")
        return 4

    return 0


if __name__ == "__main__":
    sys.exit(main())
