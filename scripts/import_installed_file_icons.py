#!/usr/bin/env python3
"""Bake selected installed VS Code themes into Diffy's offline icon resources.

Usage:
  python3 scripts/import_installed_file_icons.py /tmp/diffy-icon-renderer/node_modules/@resvg/resvg-js

Use --extensions-directory to import from another VS Code installation. The
selection file pins installed versions. Only data and artwork are read; no
extension code is executed and no installed files or preferences are modified.
"""

import argparse
import hashlib
import json
from pathlib import Path
import tempfile

from import_file_icons import (
    DESTINATION, MAPPINGS, DEFAULTS, ROOT,
    render_icons, supplement_language_associations, variant,
)


def read_resource(extension, relative, fingerprints):
    path = (extension / relative).resolve()
    if not path.is_relative_to(extension.resolve()):
        raise ValueError(f'Resource is outside its extension: {relative}')
    data = path.read_bytes()
    fingerprints[path.relative_to(extension).as_posix()] = hashlib.sha256(data).hexdigest()
    return data


def namespace_associations(associations, prefix):
    for key in MAPPINGS + ('languageIds',):
        associations[key] = {name: prefix + icon for name, icon in associations[key].items()}
    for key in DEFAULTS:
        associations[key] = prefix + associations[key]


def import_variant(name, mode, specification, extension, material, destination, staging, jobs, fingerprints):
    manifest_path = Path(specification[mode])
    manifest = json.loads(read_resource(extension, manifest_path, fingerprints))
    associations = variant(manifest, mode == 'light')
    supplement_language_associations(associations, material[mode])
    # Paired Latte/Mocha themes reuse icon IDs with different artwork.
    prefix = mode + '-' if specification['light'] != specification['dark'] else ''
    namespace_associations(associations, prefix)

    if mode == 'light' and not prefix:
        return associations

    for icon, definition in manifest['iconDefinitions'].items():
        if not definition.get('iconPath'):
            continue
        if '/' in icon or '\\' in icon or icon in ('.', '..'):
            raise ValueError(f'Invalid icon identifier: {icon}')
        # Noctis ships trailing whitespace in eight Redux icon paths.
        relative = manifest_path.parent / definition['iconPath'].strip()
        if relative.suffix.lower() != '.svg':
            raise ValueError(f'Expected SVG artwork: {relative}')
        source = staging / f'{name}-{prefix}{icon}.svg'
        source.write_bytes(read_resource(extension, relative, fingerprints))
        jobs.append({'source': str(source), 'destination': str(destination / f'{prefix}{icon}.png')})
    return associations


def import_theme(name, specification, extensions, material, staging, jobs):
    extension = (extensions / specification['extension']).resolve()
    destination = DESTINATION / name
    destination.mkdir(parents=True, exist_ok=True)
    fingerprints = {}
    catalog = {}
    for mode in ('dark', 'light'):
        catalog[mode] = import_variant(
            name, mode, specification, extension, material,
            destination, staging, jobs, fingerprints,
        )
    for notice in specification['notices']:
        data = read_resource(extension, notice, fingerprints)
        (destination / Path(notice).name).write_bytes(data)
    (destination / 'catalog.json').write_text(json.dumps(catalog, indent=2, sort_keys=True) + '\n')
    provenance = {
        'extension': specification['extension'],
        'source': specification['source'],
        'adaptation': 'SVG artwork rendered at 64px with bundled Geist Mono font fallback; language associations supplemented; paired Latte/Mocha IDs namespaced.',
        'sha256': dict(sorted(fingerprints.items())),
    }
    (destination / 'source.json').write_text(json.dumps(provenance, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('renderer', type=Path)
    parser.add_argument('--extensions-directory', type=Path, default=Path.home() / '.vscode/extensions')
    arguments = parser.parse_args()
    packs = json.loads((ROOT / 'scripts/installed_file_icon_packs.json').read_text())
    material = json.loads((DESTINATION / 'material/catalog.json').read_text())
    with tempfile.TemporaryDirectory(prefix='diffy-installed-icons-') as temporary:
        staging = Path(temporary)
        jobs = []
        for name, specification in packs.items():
            import_theme(name, specification, arguments.extensions_directory, material, staging, jobs)
        render_icons(str(arguments.renderer.resolve()), jobs, staging)


if __name__ == '__main__':
    main()
