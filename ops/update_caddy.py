#!/usr/bin/env python3
"""Replace only the docktools.dev site block in an existing Caddyfile."""

from argparse import ArgumentParser
from pathlib import Path


SITE_LABEL = "docktools.dev, www.docktools.dev {"


def replace_site_block(source: str, replacement: str) -> str:
    start = source.find(SITE_LABEL)
    if start < 0:
        raise ValueError(f"site block not found: {SITE_LABEL}")
    if source.find(SITE_LABEL, start + len(SITE_LABEL)) >= 0:
        raise ValueError("more than one docktools.dev site block found")

    depth = 0
    end = None
    for index in range(start, len(source)):
        character = source[index]
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                end = index + 1
                break

    if end is None:
        raise ValueError("docktools.dev site block is not balanced")

    clean_replacement = replacement.strip()
    comment_start = clean_replacement.find(SITE_LABEL)
    if comment_start < 0:
        raise ValueError("replacement does not contain the expected site label")
    clean_replacement = clean_replacement[comment_start:]
    return source[:start] + clean_replacement + source[end:]


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("snippet", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    result = replace_site_block(
        args.source.read_text(encoding="utf-8"),
        args.snippet.read_text(encoding="utf-8"),
    )
    args.output.write_text(result, encoding="utf-8")


if __name__ == "__main__":
    main()
