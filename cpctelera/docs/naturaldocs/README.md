# CPCtelera documentation generator

The reference documentation in `docs\` is generated from the sources in `src\`
with [Natural Docs](https://naturaldocs.org) 2.3.1 (Windows, PowerShell).

Do not edit the generated files in `docs\` by hand: they are overwritten at each run.

## Generate

1. Download Natural Docs 2.3.1 from https://naturaldocs.org/download and unzip it anywhere.
2. Run, from this folder:

       .\build_doc.ps1 -NaturalDocs "C:\path\to\Natural Docs"

   (or set the `NATURALDOCS` environment variable once, then just `.\build_doc.ps1`).
   Add `-r` to force a full rebuild.

The output goes to `docs\`.  The first run on a clean checkout may need `docs\` to exist.

## Files

| File             | Purpose                                                                       |
|------------------|-------------------------------------------------------------------------------|
| `Project.txt`    | Title, copyright, source folder, images, output folder, home page (readme.txt) |
| `Languages.txt`  | Assembly sources use `.s` as well as `.asm`                                   |
| `menu_order.txt` | Order of the top level entries of the left menu (one per line)                |
| `cpctelera.css`  | Style: CPCtelera logo in the header                                           |
| `images\`        | Images used by the documentation comments, plus the logo                      |
| `build_doc.ps1`  | Runs Natural Docs, then applies `menu_order.txt` to `docs\menu\files.js`       |

`Working Data\` is Natural Docs' cache (ignored by git).  Delete it to force a rebuild.

## Writing comments (Natural Docs 2.x)

A bullet list (`*`, `-`, `+`) must be preceded by a blank line, otherwise it is
rendered as plain text inside the previous paragraph.
