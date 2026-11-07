#!/usr/bin/env python3
"""Installs a Qt build from the official online repository (download.qt.io).

Used by CI where aqtinstall does not understand the repository layout yet:
since Qt 6.11 the Windows packages live in one folder per toolchain
(e.g. qt6_6120/qt6_6120_msvc2022_64/) instead of qt6_6120/qt6_6120/.

    python tools/ci/install-qt.py --host windows_x86 --version 6.12.0 \
        --toolchain msvc2022_64 --arch win64_msvc2022_64 \
        --modules qtmultimedia --out C:/Qt

Every archive is verified against the repository's SHA-1 before it is
extracted with 7-Zip. When running on GitHub Actions the Qt location is
exported (QT_ROOT_DIR, Qt6_DIR, CMAKE_PREFIX_PATH, PATH).
"""
import argparse
import hashlib
import os
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

BASE = "https://download.qt.io/online/qtsdkrepository"
SKIP = ("qtdoc-", "qttranslations-")  # not needed to build or ship IPTVX


def fetch(url: str) -> bytes:
    with urllib.request.urlopen(url, timeout=120) as response:
        return response.read()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True)            # windows_x86
    parser.add_argument("--version", required=True)         # 6.12.0
    parser.add_argument("--toolchain", required=True)       # msvc2022_64
    parser.add_argument("--arch", required=True)            # win64_msvc2022_64
    parser.add_argument("--modules", nargs="*", default=[])
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    compact = args.version.replace(".", "")
    repo = f"{BASE}/{args.host}/desktop/qt6_{compact}/qt6_{compact}_{args.toolchain}"
    root = ET.fromstring(fetch(f"{repo}/Updates.xml"))
    packages = {p.findtext("Name"): p for p in root.iter("PackageUpdate")}

    wanted = [f"qt.qt6.{compact}.{args.arch}"]
    wanted += [f"qt.qt6.{compact}.addons.{m}.{args.arch}" for m in args.modules]

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for name in wanted:
        package = packages.get(name)
        if package is None:
            print(f"error: package {name} not found in {repo}", file=sys.stderr)
            return 1
        version = package.findtext("Version")
        archives = [a.strip() for a in (package.findtext("DownloadableArchives") or "").split(",") if a.strip()]
        for archive in archives:
            if archive.startswith(SKIP):
                continue
            url = f"{repo}/{name}/{version}{archive}"
            print(f"downloading {archive}", flush=True)
            data = fetch(url)
            expected = fetch(url + ".sha1").decode().split()[0].strip().lower()
            if hashlib.sha1(data).hexdigest() != expected:
                print(f"error: checksum mismatch for {archive}", file=sys.stderr)
                return 1
            path = out / archive
            path.write_bytes(data)
            subprocess.run(["7z", "x", "-y", f"-o{out}", str(path)], check=True, stdout=subprocess.DEVNULL)
            path.unlink()

    qt_dir = out / args.version / args.toolchain
    if not (qt_dir / "bin").is_dir():
        print(f"error: {qt_dir} was not created", file=sys.stderr)
        return 1
    # Relocated installs need a qt.conf next to qmake / qtpaths.
    (qt_dir / "bin" / "qt.conf").write_text("[Paths]\nPrefix=..\n")
    print(f"Qt installed in {qt_dir}")

    env_file = os.environ.get("GITHUB_ENV")
    path_file = os.environ.get("GITHUB_PATH")
    if env_file:
        with open(env_file, "a", encoding="utf-8") as env:
            env.write(f"QT_ROOT_DIR={qt_dir}\n")
            env.write(f"Qt6_DIR={qt_dir / 'lib' / 'cmake' / 'Qt6'}\n")
            env.write(f"CMAKE_PREFIX_PATH={qt_dir}\n")
    if path_file:
        with open(path_file, "a", encoding="utf-8") as path:
            path.write(f"{qt_dir / 'bin'}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
