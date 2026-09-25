#!/usr/bin/env python3
"""Import pinned VS Code file themes as offline, 64px PNG resources.

Requires Node.js and @resvg/resvg-js 2.6.2 in a temporary directory:
  npm install --prefix /tmp/diffy-icon-renderer @resvg/resvg-js@2.6.2
  python3 scripts/import_file_icons.py /tmp/diffy-icon-renderer/node_modules/@resvg/resvg-js

No extension code is executed. Only manifests, SVGs, and licenses are read.
"""

import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DESTINATION = ROOT / 'Diffy/Resources/FileIcons'
PACKS = {
    'material': {
        'url': 'https://open-vsx.org/api/PKief/material-icon-theme/5.38.1/file/PKief.material-icon-theme-5.38.1.vsix',
        'sha256': 'fa7515831a2d68b1f78bd02de40f96260bfe74efb03a238c2bde70265e04b696',
        'manifest': 'extension/dist/material-icons.json',
    },
    'vscode': {
        'url': 'https://open-vsx.org/api/vscode-icons-team/vscode-icons/12.19.0/file/vscode-icons-team.vscode-icons-12.19.0.vsix',
        'sha256': '6891095459234809b9c5161850f2dabc91a80b3eca2daf599d050a88b455e960',
        'manifest': 'extension/dist/src/vsicons-icon-theme.json',
    },
}
MAPPINGS = ('fileNames', 'fileExtensions', 'folderNames', 'folderNamesExpanded')
DEFAULTS = ('file', 'folder', 'folderExpanded')
LANGUAGE_ASSOCIATIONS = json.loads((ROOT / 'scripts/file_icon_languages.json').read_text())


def read_pack(specification):
    data = urllib.request.urlopen(specification['url']).read()
    if hashlib.sha256(data).hexdigest() != specification['sha256']:
        raise ValueError('Icon archive checksum does not match the pinned release')
    archive = zipfile.ZipFile(io.BytesIO(data))
    return archive, json.loads(archive.read(specification['manifest']))


def variant(manifest, light):
    overrides = manifest.get('light', {}) if light else {}
    valid = {key for key, value in manifest['iconDefinitions'].items() if value['iconPath']}
    result = {}
    for key in MAPPINGS + ('languageIds',):
        merged = {**manifest.get(key, {}), **overrides.get(key, {})}
        result[key] = {name.lower(): icon for name, icon in merged.items() if icon in valid}
    if not result['folderNamesExpanded']:
        result['folderNamesExpanded'] = dict(result['folderNames'])
    for key in DEFAULTS:
        override = overrides.get(key)
        fallback = manifest.get(key, manifest['folder'] if key == 'folderExpanded' else manifest['file'])
        result[key] = override if override in valid else fallback
    return result


def supplement_language_associations(target, source):
    # VSCode Icons delegates most language extensions to the editor. Reuse the
    # complete Material path associations to resolve these without an editor.
    for key in ('fileNames', 'fileExtensions'):
        for name, language in LANGUAGE_ASSOCIATIONS[key].items():
            if language in target['languageIds'] and name not in target[key]:
                target[key][name] = target['languageIds'][language]

    languages_by_icon = {}
    for language, icon in source['languageIds'].items():
        if language in target['languageIds']:
            languages_by_icon.setdefault(icon, []).append(language)
    for key in ('fileNames', 'fileExtensions'):
        for name, icon in source[key].items():
            languages = languages_by_icon.get(icon, [])
            if languages and name not in target[key]:
                preferred = {'console': 'shellscript', 'settings': 'properties'}.get(icon)
                language = name if name in languages else preferred if preferred in languages else languages[0]
                target[key][name] = target['languageIds'][language]


def svg_archive_path(manifest_path, relative_path):
    parts = []
    for part in (PurePosixPath(manifest_path).parent / relative_path).parts:
        if part == '..':
            parts.pop()
        elif part != '.':
            parts.append(part)
    return '/'.join(parts)


def import_pack(name, archive, manifest, material_manifest, staging, render_jobs):
    destination = DESTINATION / name
    destination.mkdir(parents=True, exist_ok=True)
    catalog = {}
    for light in (False, True):
        associations = variant(manifest, light)
        if name == 'vscode':
            supplement_language_associations(associations, variant(material_manifest, light))
        catalog['light' if light else 'dark'] = associations
    (destination / 'catalog.json').write_text(json.dumps(catalog, indent=2, sort_keys=True) + '\n')
    (destination / 'LICENSE.txt').write_bytes(archive.read('extension/LICENSE.txt'))
    for icon, definition in manifest['iconDefinitions'].items():
        if not definition['iconPath']:
            continue
        if '/' in icon or '\\' in icon or icon in ('.', '..'):
            raise ValueError(f'Invalid icon identifier: {icon}')
        source = staging / f'{name}-{icon}.svg'
        source.write_bytes(archive.read(svg_archive_path(PACKS[name]['manifest'], definition['iconPath'])))
        render_jobs.append({'source': str(source), 'destination': str(destination / f'{icon}.png')})
    print(f'{name}: {len(manifest["iconDefinitions"])} definitions imported')


def render_icons(renderer, jobs, staging):
    job_file = staging / 'jobs.json'
    job_file.write_text(json.dumps(jobs))
    subprocess.run(['node', '-e', '''
const fs = require('fs');
const { Resvg } = require(process.argv[1]);
const font = {
    loadSystemFonts: false,
    fontDirs: [process.argv[3]],
    defaultFontFamily: 'Geist Mono',
    sansSerifFamily: 'Geist Mono',
    serifFamily: 'Geist Mono',
    monospaceFamily: 'Geist Mono',
};
for (const job of JSON.parse(fs.readFileSync(process.argv[2], 'utf8'))) {
    const svg = fs.readFileSync(job.source);
    const renderer = new Resvg(svg, { fitTo: { mode: 'width', value: 64 }, font });
    const rendered = renderer.render();
    if (!rendered.pixels.some((value, index) => index % 4 === 3 && value > 0)) {
        throw new Error(`Icon rendered without visible pixels: ${job.source}`);
    }
    fs.writeFileSync(job.destination, rendered.asPng());
}
''', renderer, str(job_file), str(ROOT / 'Diffy/Resources/Fonts')], check=True)
    print(f'Rendered {len(jobs)} icons at 64px')


def main():
    renderer = str(Path(sys.argv[1]).resolve())
    packs = {name: read_pack(specification) for name, specification in PACKS.items()}
    with tempfile.TemporaryDirectory(prefix='diffy-file-icons-') as temporary:
        staging = Path(temporary)
        jobs = []
        for name, (archive, manifest) in packs.items():
            import_pack(name, archive, manifest, packs['material'][1], staging, jobs)
        render_icons(renderer, jobs, staging)


if __name__ == '__main__':
    main()
