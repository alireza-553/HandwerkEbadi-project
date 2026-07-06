$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$outDir = Join-Path $root 'docs\presentation'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$pptPath = Join-Path $outDir 'HandwerkEbadi_PR_Plan_v2.pptx'
$handoutDocxPath = Join-Path $outDir 'HandwerkEbadi_PR_Handout_v2.docx'
$handoutMdPath = Join-Path $outDir 'HandwerkEbadi_PR_Handout_v2.md'

$prs = @(
  @{N='1'; Owner='alireza-553'; Branch='alireza/game-shell-v2'; Title='Create canvas game shell v2'; Goal='Vue/Vite demo wird zur Canvas-Spiel-Shell.'; Files='src/App.vue, src/style.css'; Changes='Canvas, ResizeObserver, Render-Loop, HUD, Stage, Controls, Vollbild-Layout'; Test='npm run build'},
  @{N='2'; Owner='HandweNic'; Branch='handwenic/subway-runner-base-v2'; Title='Add subway runner gameplay v2'; Goal='Aus der Shell wird ein spielbarer Subway Runner.'; Files='src/App.vue, src/style.css'; Changes='3 Spuren, Spurwechsel, Coins, Hindernisse, Score, Bestscore, Start, Game Over, Restart'; Test='Spurwechsel, Coins, Hindernisse, Restart, npm run build'},
  @{N='3'; Owner='alireza-553'; Branch='alireza/runner-controls-v2'; Title='Improve runner controls and collisions v2'; Goal='Runner-Steuerung wird fairer und vollstaendiger.'; Files='src/App.vue, src/style.css'; Changes='Jump, Slide, High-/Low-Hindernisse, fairere Hitboxen, Keyboard- und Touch-Controls'; Test='Low ueberspringen, High unterrutschen, npm run build'},
  @{N='4'; Owner='HandweNic'; Branch='handwenic/runner-visuals-v2'; Title='Improve runner character and obstacles v2'; Goal='Runner und Hindernisse werden visuell klarer.'; Files='src/App.vue'; Changes='Runner-Figur, Laufpose, Slide-Pose, Gate, Barrier, Cone, Crate'; Test='Visuals und bestehende Kollisionen pruefen, npm run build'},
  @{N='5'; Owner='alireza-553'; Branch='alireza/runner-polish-v2'; Title='Polish runner pacing and excitement v2'; Goal='Runner bekommt mehr Feedback und Motivation.'; Files='src/App.vue, src/style.css'; Changes='Combo, Multiplikator, Partikel, Feedback-Messages, Combo-HUD, Pacing-Anpassung'; Test='Combo sammeln, Reset pruefen, Mobile HUD, npm run build'},
  @{N='6'; Owner='HandweNic'; Branch='handwenic/neon-shooter-base-v2'; Title='Convert runner into neon shooter v2'; Goal='Bewusster Genre-Wechsel vom Runner zum Neon Shooter.'; Files='src/App.vue, src/style.css'; Changes='Spieler-Schiff, freie Bewegung, Schuesse, Gegner, Waves, Powerups, Lives, Charge, Fire-Button'; Test='Bewegen, schiessen, Gegner, Game Over, Powerups, npm run build'},
  @{N='7'; Owner='alireza-553'; Branch='alireza/lan-player-relay-v2'; Title='Add LAN player relay v2'; Goal='Erste LAN-Multiplayer-Grundlage.'; Files='src/App.vue, src/style.css, vite.config.js'; Changes='Player-ID, Remote-Spieler, Remote-Schuesse, Online/Mode-HUD, Vite WebSocket Relay'; Test='2 Clients im WLAN, Online-Anzeige, Remote-Spieler, npm run build'},
  @{N='8'; Owner='HandweNic'; Branch='handwenic/shared-enemy-world-v2'; Title='Sync shared enemy world over LAN v2'; Goal='Alle LAN-Spieler teilen dieselbe Gegnerwelt.'; Files='src/App.vue, vite.config.js'; Changes='Host-Wahl, hostPayload, applyWorld, normalisierte Entities, shooter:world Relay'; Test='2 Clients, gleiche Gegner/Waves, Host-Wechsel, npm run build'},
  @{N='9'; Owner='alireza-553'; Branch='alireza/lan-delay-polish-v2'; Title='Reduce LAN multiplayer delay v2'; Goal='LAN-Sync fuehlt sich direkter an.'; Files='src/App.vue, vite.config.js'; Changes='NETWORK_SEND_INTERVAL, WORLD_SYNC_INTERVAL, shooter:player Einzelupdates, kuerzere stale-player Zeit'; Test='2 Clients, Bewegungsdelay, Online cleanup, npm run build'},
  @{N='10'; Owner='HandweNic'; Branch='handwenic/test-and-docs-v2'; Title='Document shooter LAN setup v2'; Goal='Start, Build, Steuerung und LAN-Test werden dokumentiert.'; Files='README.md'; Changes='Lokaler Start, LAN-Start, Beispiel-IP, Steuerung, Multiplayer-Testplan'; Test='README nachvollziehen, npm run build'}
)

function Add-TextBox {
  param($Slide, [string]$Text, [single]$Left, [single]$Top, [single]$Width, [single]$Height, [int]$FontSize = 18, [int]$Color = 0xFFFFFF, [switch]$Bold)
  $box = $Slide.Shapes.AddTextbox(1, $Left, $Top, $Width, $Height)
  $box.TextFrame.TextRange.Text = $Text
  $box.TextFrame.TextRange.Font.Name = 'Aptos'
  $box.TextFrame.TextRange.Font.Size = $FontSize
  $box.TextFrame.TextRange.Font.Color.RGB = $Color
  $box.TextFrame.TextRange.Font.Bold = [int]$Bold.IsPresent
  $box.TextFrame.MarginLeft = 0
  $box.TextFrame.MarginRight = 0
  $box.TextFrame.MarginTop = 0
  $box.TextFrame.MarginBottom = 0
  return $box
}

function Add-Rect {
  param($Slide, [single]$Left, [single]$Top, [single]$Width, [single]$Height, [int]$Fill, [int]$Line = 0xFFFFFF, [single]$Transparency = 0)
  $shape = $Slide.Shapes.AddShape(1, $Left, $Top, $Width, $Height)
  $shape.Fill.ForeColor.RGB = $Fill
  $shape.Fill.Transparency = $Transparency
  $shape.Line.ForeColor.RGB = $Line
  $shape.Line.Transparency = 0.72
  return $shape
}

function Add-Header {
  param($Slide, [string]$Title, [string]$Kicker = 'HandwerkEbadi-project')
  Add-TextBox $Slide $Kicker 42 22 820 20 11 0xA7F3D0 | Out-Null
  Add-TextBox $Slide $Title 42 48 860 54 30 0xFFFFFF -Bold | Out-Null
}

$pp = New-Object -ComObject PowerPoint.Application
$pp.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue
$presentation = $pp.Presentations.Add()
$presentation.PageSetup.SlideWidth = 960
$presentation.PageSetup.SlideHeight = 540

function New-Slide {
  $slide = $presentation.Slides.Add($presentation.Slides.Count + 1, 12)
  $slide.FollowMasterBackground = $false
  $slide.Background.Fill.ForeColor.RGB = 0x111827
  return $slide
}

$slide = New-Slide
Add-Rect $slide 0 0 960 540 0x0F172A 0x0F172A | Out-Null
Add-Rect $slide 42 376 876 84 0x1F2937 0x38BDF8 0.08 | Out-Null
Add-TextBox $slide 'HandwerkEbadi PR-Plan v2' 54 78 820 54 36 0xFFFFFF -Bold | Out-Null
Add-TextBox $slide 'Schrittweiser Aufbau vom Canvas-Grundlayout zum LAN-faehigen Neon-Shooter' 56 144 800 40 18 0xCBD5E1 | Out-Null
Add-TextBox $slide '10 kleine Pull Requests | klare Owner | saubere Merge-Reihenfolge | UTF-8 statt Binary-Diffs' 56 398 820 34 18 0xFACC15 -Bold | Out-Null

$slide = New-Slide
Add-Header $slide 'Warum wir die v2-Branches brauchen'
Add-Rect $slide 42 126 260 310 0x1F2937 0x38BDF8 0.05 | Out-Null
Add-Rect $slide 350 126 260 310 0x1F2937 0xFACC15 0.05 | Out-Null
Add-Rect $slide 658 126 260 310 0x1F2937 0x22C55E 0.05 | Out-Null
Add-TextBox $slide "Problem`nAlte PRs enthielten teils zu grosse oder falsch codierte Dateien. GitHub zeigte dadurch binary/0-line Diffs." 66 152 214 210 18 0xFFFFFF | Out-Null
Add-TextBox $slide "Loesung`nNeue -v2 Branches mit kleinen, nachvollziehbaren Commits und UTF-8 Textdateien." 374 152 214 210 18 0xFFFFFF | Out-Null
Add-TextBox $slide "Ergebnis`nJeder PR hat klare Aufgabe, klare Dateien und einen Testplan. Mergen nur Schritt fuer Schritt." 682 152 214 210 18 0xFFFFFF | Out-Null

$slide = New-Slide
Add-Header $slide 'Merge-Reihenfolge'
$y = 124
foreach ($pr in $prs) {
  $color = if ($pr.Owner -eq 'alireza-553') { 0x1D4ED8 } else { 0x7C3AED }
  Add-Rect $slide 48 $y 38 28 $color 0xFFFFFF 0 | Out-Null
  Add-TextBox $slide $pr.N 60 ($y + 3) 24 20 14 0xFFFFFF -Bold | Out-Null
  Add-TextBox $slide $pr.Branch 104 ($y + 2) 360 24 14 0xFFFFFF -Bold | Out-Null
  Add-TextBox $slide $pr.Title 478 ($y + 2) 410 24 14 0xCBD5E1 | Out-Null
  $y += 34
}

$slide = New-Slide
Add-Header $slide 'Rollen und Verantwortung'
Add-Rect $slide 72 138 364 260 0x1D4ED8 0x93C5FD 0.12 | Out-Null
Add-Rect $slide 524 138 364 260 0x7C3AED 0xC4B5FD 0.12 | Out-Null
Add-TextBox $slide "alireza-553`n`n1 Game Shell`n3 Runner Controls`n5 Runner Polish`n7 LAN Player Relay`n9 LAN Delay Polish" 100 170 306 180 22 0xFFFFFF -Bold | Out-Null
Add-TextBox $slide "HandweNic`n`n2 Subway Runner Base`n4 Runner Visuals`n6 Neon Shooter Base`n8 Shared Enemy World`n10 Test and Docs" 552 170 306 180 22 0xFFFFFF -Bold | Out-Null

$slide = New-Slide
Add-Header $slide 'PRs 1-5: Runner-Aufbau'
$y = 116
foreach ($pr in $prs[0..4]) {
  Add-Rect $slide 42 $y 876 64 0x1F2937 0x334155 0.05 | Out-Null
  Add-TextBox $slide ("#" + $pr.N + "  " + $pr.Branch) 62 ($y + 10) 360 20 14 0xA7F3D0 -Bold | Out-Null
  Add-TextBox $slide $pr.Goal 62 ($y + 33) 360 18 12 0xCBD5E1 | Out-Null
  Add-TextBox $slide $pr.Changes 442 ($y + 12) 440 34 12 0xFFFFFF | Out-Null
  $y += 74
}

$slide = New-Slide
Add-Header $slide 'PRs 6-10: Shooter und LAN'
$y = 116
foreach ($pr in $prs[5..9]) {
  Add-Rect $slide 42 $y 876 64 0x1F2937 0x334155 0.05 | Out-Null
  Add-TextBox $slide ("#" + $pr.N + "  " + $pr.Branch) 62 ($y + 10) 390 20 14 0xFACC15 -Bold | Out-Null
  Add-TextBox $slide $pr.Goal 62 ($y + 33) 390 18 12 0xCBD5E1 | Out-Null
  Add-TextBox $slide $pr.Changes 470 ($y + 12) 420 34 12 0xFFFFFF | Out-Null
  $y += 74
}

$slide = New-Slide
Add-Header $slide 'Qualitaetsregeln fuer jeden PR'
$rules = @(
  'Nur die Aufgabe aus dem Branch umsetzen, keine fertige tmpprj-Datei komplett kopieren.',
  'Dateien als UTF-8 speichern, damit GitHub echte Text-Diffs zeigt.',
  'Nach jedem Merge den naechsten Branch auf den neuen main-Stand bringen.',
  'Vor jedem PR npm run build ausfuehren.',
  'PR-Beschreibung mit Ziel, Aenderungen, Dateien, Nicht enthalten und Testplan ausfuellen.'
)
$y = 130
foreach ($rule in $rules) {
  Add-Rect $slide 70 $y 24 24 0x22C55E 0x22C55E | Out-Null
  Add-TextBox $slide $rule 112 ($y - 1) 760 28 18 0xFFFFFF | Out-Null
  $y += 56
}

$slide = New-Slide
Add-Header $slide 'Testplan'
Add-Rect $slide 58 130 394 260 0x1F2937 0x38BDF8 0.05 | Out-Null
Add-Rect $slide 508 130 394 260 0x1F2937 0xFACC15 0.05 | Out-Null
Add-TextBox $slide "Lokaler Test`n`nnpm install`nnpm run dev`nnpm run build`n`nPruefen: Startscreen, Gameplay, Mobile Buttons, Game Over, Restart" 88 158 330 190 18 0xFFFFFF | Out-Null
Add-TextBox $slide "LAN-Test`n`nnpm run dev -- --host 0.0.0.0 --port 5173`n`nZwei Browser/Geraete im selben WLAN oeffnen. Online, Remote-Spieler, Schuesse und Gegnerwelt pruefen." 538 158 330 210 18 0xFFFFFF | Out-Null

$slide = New-Slide
Add-Header $slide 'Was beim Mergen wichtig ist'
Add-TextBox $slide "1. PR #1 mergen.`n2. Danach PR #2 gegen neuen main aktualisieren.`n3. Erst dann PR #2 mergen.`n4. So weiter bis PR #10.`n`nNicht mehrere PRs ungeprueft parallel in main mergen, weil spaetere PRs auf frueheren Branches aufbauen." 84 136 792 230 24 0xFFFFFF | Out-Null
Add-Rect $slide 84 398 792 54 0x7F1D1D 0xFCA5A5 0.08 | Out-Null
Add-TextBox $slide 'Wenn GitHub "binary file changed" oder "0 additions" zeigt: Encoding pruefen, Branch nicht mergen.' 106 414 748 28 18 0xFCA5A5 -Bold | Out-Null

$slide = New-Slide
Add-Header $slide 'Naechster Schritt'
Add-TextBox $slide "Jetzt PRs in dieser Reihenfolge erstellen und mergen:`n`n1 alireza/game-shell-v2`n2 handwenic/subway-runner-base-v2`n3 alireza/runner-controls-v2`n4 handwenic/runner-visuals-v2`n5 alireza/runner-polish-v2`n6 handwenic/neon-shooter-base-v2`n7 alireza/lan-player-relay-v2`n8 handwenic/shared-enemy-world-v2`n9 alireza/lan-delay-polish-v2`n10 handwenic/test-and-docs-v2" 94 130 760 320 22 0xFFFFFF | Out-Null

$presentation.SaveAs($pptPath, 24)
$presentation.Close()
$pp.Quit()

$md = @"
# HandwerkEbadi PR-Plan v2 Handout

## Ziel

Das Spiel wird in zehn kleine Pull Requests aufgeteilt. Jeder PR hat eine klare Aufgabe, einen Owner, eine kleine Dateimenge und einen Testplan. Die neuen `-v2` Branches ersetzen die alten problematischen Branches.

## Merge-Reihenfolge

| Nr. | Owner | Branch | Aufgabe | Dateien |
| --- | --- | --- | --- | --- |
"@
foreach ($pr in $prs) {
  $md += "`n| $($pr.N) | $($pr.Owner) | `$($pr.Branch)` | $($pr.Title) | $($pr.Files) |"
}

$md += @"

## Wichtige Regeln

- Immer nur einen PR mergen.
- Nach jedem Merge den naechsten Branch gegen den neuen `main` aktualisieren.
- Dateien als UTF-8 speichern.
- Keine komplette fertige Datei aus `tmpprj` kopieren.
- Vor jedem PR `npm run build` ausfuehren.

## Details pro PR

"@
foreach ($pr in $prs) {
  $md += @"
### $($pr.N). $($pr.Branch)

**Owner:** $($pr.Owner)

**Ziel:** $($pr.Goal)

**Aenderungen:** $($pr.Changes)

**Dateien:** $($pr.Files)

**Test:** $($pr.Test)

"@
}

$md | Set-Content -Path $handoutMdPath -Encoding UTF8

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Add()
$selection = $word.Selection
$selection.Font.Name = 'Aptos Display'
$selection.Font.Size = 22
$selection.Font.Bold = $true
$selection.TypeText('HandwerkEbadi PR-Plan v2 Handout')
$selection.TypeParagraph()
$selection.Font.Name = 'Aptos'
$selection.Font.Size = 11
$selection.Font.Bold = $false
$selection.TypeText("Ziel: Das Spiel wird in zehn kleine Pull Requests aufgeteilt. Jeder PR hat eine klare Aufgabe, einen Owner, eine kleine Dateimenge und einen Testplan.")
$selection.TypeParagraph()
$selection.TypeParagraph()
$selection.Font.Name = 'Aptos Display'
$selection.Font.Size = 16
$selection.Font.Bold = $true
$selection.TypeText('Merge-Reihenfolge')
$selection.TypeParagraph()
$selection.Font.Name = 'Aptos'
$selection.Font.Size = 11
$selection.Font.Bold = $false
foreach ($pr in $prs) {
  $selection.TypeText("$($pr.N). $($pr.Branch) - $($pr.Title) [$($pr.Owner)]")
  $selection.TypeParagraph()
}
$selection.TypeParagraph()
$selection.Font.Name = 'Aptos Display'
$selection.Font.Size = 16
$selection.Font.Bold = $true
$selection.TypeText('Details pro PR')
$selection.TypeParagraph()
foreach ($pr in $prs) {
  $selection.Font.Name = 'Aptos Display'
  $selection.Font.Size = 13
  $selection.Font.Bold = $true
  $selection.TypeText("$($pr.N). $($pr.Branch)")
  $selection.TypeParagraph()
  $selection.Font.Name = 'Aptos'
  $selection.Font.Size = 11
  $selection.Font.Bold = $false
  $selection.TypeText("Owner: $($pr.Owner)")
  $selection.TypeParagraph()
  $selection.TypeText("Ziel: $($pr.Goal)")
  $selection.TypeParagraph()
  $selection.TypeText("Aenderungen: $($pr.Changes)")
  $selection.TypeParagraph()
  $selection.TypeText("Dateien: $($pr.Files)")
  $selection.TypeParagraph()
  $selection.TypeText("Test: $($pr.Test)")
  $selection.TypeParagraph()
  $selection.TypeParagraph()
}
$doc.SaveAs2($handoutDocxPath, 16)
$doc.Close()
$word.Quit()

Write-Host "Created:"
Write-Host $pptPath
Write-Host $handoutDocxPath
Write-Host $handoutMdPath
