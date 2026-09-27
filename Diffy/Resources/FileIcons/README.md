# File icon themes

These resources are bundled in both Diffy targets. No network connection, VS Code
installation, or extension execution is required at runtime.

## Material Icon Theme 5.38.1

- Authors: Material Extensions and contributors; originally Philipp Kief.
- Source: https://github.com/material-extensions/vscode-material-icon-theme
- Release: https://open-vsx.org/extension/PKief/material-icon-theme
- License: MIT; see `material/LICENSE.txt`.
- Includes all 1,251 icon definitions in the published default theme, with light
  variants, named folders, and expanded folders.

## VSCode Icons 12.19.0

- Authors: Roberto Huertas, the vscode-icons team, and contributors.
- Source: https://github.com/vscode-icons/vscode-icons
- Release: https://open-vsx.org/extension/vscode-icons-team/vscode-icons
- Theme mapping/source license: MIT; see `vscode/LICENSE.txt`.
- Artwork license: Creative Commons Attribution-ShareAlike 4.0 International;
  see `vscode/CC-BY-SA-4.0.txt` and https://creativecommons.org/licenses/by-sa/4.0/.
- Branded icons remain subject to their respective copyright licenses, as stated
  by upstream: https://github.com/vscode-icons/vscode-icons#license.
- Includes all 1,396 nonempty icon definitions in the published default theme.
  The five empty light defaults inherit the regular defaults.

## Installed Catppuccin and NewAge collections

Imported from the user's installed VS Code extensions, retaining their original
MIT license notices and the complete definitions from these theme manifests:

| Collection | Installed version | Bundled artwork | Source |
| --- | --- | --- | --- |
| Catppuccin | 1.26.0 | 656 icons × Latte/Mocha = 1,312 PNGs | https://github.com/catppuccin/vscode-icons |
| Catppuccin Perfect | 0.21.33 | 676 icons × Latte/Mocha = 1,352 PNGs | https://github.com/thang-nm/Catppuccin-Perfect-Icons |
| Catppuccin Noctis | 0.3.0 | 240 icons | https://github.com/alexdauenhauer/catppuccin-noctis-icons |
| NewAge Icons | 1.2.0 | 158 icons | https://github.com/bynyck/newage-icons |

Catppuccin and Catppuccin Perfect use Latte in light mode and Mocha in dark mode.
Noctis and NewAge provide one palette for both. Noctis uses its closed folder
artwork for expanded folders because its manifest has no expanded variants.
Eight Noctis resource paths had trailing whitespace; the importer trims it.
NewAge's text-based glyphs use Diffy's bundled Geist Mono as the font fallback
during rasterization, replacing unavailable Segoe UI/Consolas/system fonts.
The bundled font's OFL notice is in `../Fonts/GeistMono-OFL.txt`. The importer
rejects entirely transparent images so missing glyphs cannot silently ship.

Each collection's folder includes `LICENSE.txt` and `source.json`, recording its
extension version, source repository, and SHA-256 fingerprints of the imported
manifests and artwork. Catppuccin credits Catppuccin and thang-nm; Noctis retains
its upstream Miguel Solorio notice. NewAge retains its contributors' notice,
`SETI_ATTRIBUTION.md`, `SETI-LICENSE.txt`, and `TRADEMARKS.md`.

The six bundled artwork collections total 5,709 PNGs. Native Symbols uses system
artwork. Settings previews 27 common file types plus closed and expanded folders.

## Adaptations and maintenance

SVG artwork has been rasterized to transparent 64px PNG with resvg 2.6.2. Original
colors and proportions are retained. The converted VSCode Icons artwork remains
available under CC BY-SA 4.0, subject to upstream's branded-artwork notice above.
Diffy uses it solely to identify corresponding file types and tools; no affiliation
or endorsement is implied.

Catalogs retain all published filename, extension, folder, and language-ID mappings
for both appearances. Some themes rely on the editor for language associations.
Diffy first supplements their explicit mappings with the built-in
language associations from VS Code 1.139.0, then Material Icon Theme's additional
path-to-language associations. Each theme's explicit mappings take precedence.
The imported language associations are already stored in the bundled catalogs;
their MIT license is `VSCode-LANGUAGE-LICENSE.txt`.
Editor extension detection, user-defined packs, and project auto-detection are not
executed. Unknown paths use the theme's generic file/folder icon.

The entire FileIcons folder is included as a resource in Live and Mock. Licenses
and this attribution travel with both apps. The files are self-contained: end
users do not need VS Code, Node.js, the extensions, or access to the developer's
home directory.

The import tools have been removed. Future collection updates require manually
rebuilding the PNG artwork and catalogs from the upstream sources listed above,
preserving the license notices and updating provenance where provided.
