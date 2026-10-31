# Builds the CPCtelera documentation with Natural Docs 2.x into docs\ (the
# parent of this folder), then reorders the top level of the file menu according
# to menu_order.txt (Natural Docs 2.x has no Menu.txt anymore: it only lists the
# source tree alphabetically).
#
# Usage:  .\build_doc.ps1 [-NaturalDocs <path to NaturalDocs.exe or its folder>] [extra Natural Docs options, e.g. -r]
# If -NaturalDocs is not given, the NATURALDOCS environment variable is used,
# then NaturalDocs.exe from the PATH.
param(
    [string]$NaturalDocs = $env:NATURALDOCS,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$NdArgs
)

$project = $PSScriptRoot
$html    = Split-Path $project -Parent

if (-not $NaturalDocs) {
    $cmd = Get-Command NaturalDocs.exe -ErrorAction SilentlyContinue
    if ($cmd) { $NaturalDocs = $cmd.Source }
}
if ($NaturalDocs -and (Test-Path $NaturalDocs -PathType Container)) {
    $NaturalDocs = Join-Path $NaturalDocs 'NaturalDocs.exe'
}
if (-not $NaturalDocs -or -not (Test-Path $NaturalDocs)) {
    throw "NaturalDocs.exe not found: use -NaturalDocs <path> or set the NATURALDOCS environment variable (see README.md)."
}

& $NaturalDocs $project @NdArgs
if ($LASTEXITCODE -ne 0) { throw "Natural Docs failed ($LASTEXITCODE)" }

$menu  = Join-Path $html 'menu\files.js'
$text  = [IO.File]::ReadAllText($menu)
$open  = $text.IndexOf(',[') + 1

# Splits the array starting at $s.Text[$s.Open] into its entries; returns the entries and the index of the closing bracket
function Split-JsArray([string]$s, [int]$open) {
    $depth = 0; $inStr = $false; $start = -1; $items = @()
    for ($i = $open; $i -lt $s.Length; $i++) {
        $c = $s[$i]
        if ($c -eq '"') { $inStr = -not $inStr; continue }
        if ($inStr) { continue }
        if ($c -eq '[') { $depth++; if ($depth -eq 2) { $start = $i } }
        elseif ($c -eq ']') {
            if ($depth -eq 2) { $items += $s.Substring($start, $i - $start + 1) }
            $depth--
            if ($depth -eq 0) { return @{ Items = $items; End = $i } }
        }
    }
}

$top   = Split-JsArray $text $open
$items = @(); $end = $top.End
foreach ($it in $top.Items) {
    # With several source folders Natural Docs adds a root entry per folder: the main one (cpctelera) is
    # flattened to get its entries at the top level of the menu, like before
    if ($it -match '^\[2,"cpctelera","File:",\[') {
        $inner  = Split-JsArray $it ($it.IndexOf(',[') + 1)
        $items += $inner.Items
    } else { $items += $it }
}

# Entry name = second field: [type,"name",...]
$byName = @{}
foreach ($it in $items) { if ($it -match '^\[\d,"([^"]+)"') { $byName[$Matches[1].ToLower()] = $it } }

$ordered = @()
foreach ($n in (Get-Content (Join-Path $project 'menu_order.txt') | Where-Object { $_.Trim() })) {
    $k = $n.Trim().ToLower()
    if ($byName.ContainsKey($k)) { $ordered += $byName[$k]; $byName.Remove($k) }
}
$ordered += ($byName.Keys | Sort-Object | ForEach-Object { $byName[$_] })   # anything not listed

$new = $text.Substring(0, $open) + '[' + ($ordered -join ',') + $text.Substring($end)
[IO.File]::WriteAllText($menu, $new, (New-Object Text.UTF8Encoding $false))
Write-Host "Menu reordered ($($ordered.Count) entries)."

# Natural Docs only copies images that are referenced from comments; the header logo (see cpctelera.css) is not
Copy-Item (Join-Path $project 'images\cpct_logo_long_190x49.png') (Join-Path $html 'images') -Force
