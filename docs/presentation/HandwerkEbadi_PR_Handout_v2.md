# HandwerkEbadi PR-Plan v2 Handout

## Ziel

Das Spiel wird in zehn kleine Pull Requests aufgeteilt. Jeder PR hat eine klare Aufgabe, einen Owner, eine kleine Dateimenge und einen Testplan. Die neuen -v2 Branches ersetzen die alten problematischen Branches.

## Merge-Reihenfolge

| Nr. | Owner | Branch | Aufgabe | Dateien |
| --- | --- | --- | --- | --- |
| 1 | alireza-553 | $(System.Collections.Hashtable.Branch) | Create canvas game shell v2 | src/App.vue, src/style.css |
| 2 | HandweNic | $(System.Collections.Hashtable.Branch) | Add subway runner gameplay v2 | src/App.vue, src/style.css |
| 3 | alireza-553 | $(System.Collections.Hashtable.Branch) | Improve runner controls and collisions v2 | src/App.vue, src/style.css |
| 4 | HandweNic | $(System.Collections.Hashtable.Branch) | Improve runner character and obstacles v2 | src/App.vue |
| 5 | alireza-553 | $(System.Collections.Hashtable.Branch) | Polish runner pacing and excitement v2 | src/App.vue, src/style.css |
| 6 | HandweNic | $(System.Collections.Hashtable.Branch) | Convert runner into neon shooter v2 | src/App.vue, src/style.css |
| 7 | alireza-553 | $(System.Collections.Hashtable.Branch) | Add LAN player relay v2 | src/App.vue, src/style.css, vite.config.js |
| 8 | HandweNic | $(System.Collections.Hashtable.Branch) | Sync shared enemy world over LAN v2 | src/App.vue, vite.config.js |
| 9 | alireza-553 | $(System.Collections.Hashtable.Branch) | Reduce LAN multiplayer delay v2 | src/App.vue, vite.config.js |
| 10 | HandweNic | $(System.Collections.Hashtable.Branch) | Document shooter LAN setup v2 | README.md |
## Wichtige Regeln

- Immer nur einen PR mergen.
- Nach jedem Merge den naechsten Branch gegen den neuen main aktualisieren.
- Dateien als UTF-8 speichern.
- Keine komplette fertige Datei aus 	mpprj kopieren.
- Vor jedem PR 
pm run build ausfuehren.

## Details pro PR
### 1. alireza/game-shell-v2

**Owner:** alireza-553

**Ziel:** Vue/Vite demo wird zur Canvas-Spiel-Shell.

**Aenderungen:** Canvas, ResizeObserver, Render-Loop, HUD, Stage, Controls, Vollbild-Layout

**Dateien:** src/App.vue, src/style.css

**Test:** npm run build
### 2. handwenic/subway-runner-base-v2

**Owner:** HandweNic

**Ziel:** Aus der Shell wird ein spielbarer Subway Runner.

**Aenderungen:** 3 Spuren, Spurwechsel, Coins, Hindernisse, Score, Bestscore, Start, Game Over, Restart

**Dateien:** src/App.vue, src/style.css

**Test:** Spurwechsel, Coins, Hindernisse, Restart, npm run build
### 3. alireza/runner-controls-v2

**Owner:** alireza-553

**Ziel:** Runner-Steuerung wird fairer und vollstaendiger.

**Aenderungen:** Jump, Slide, High-/Low-Hindernisse, fairere Hitboxen, Keyboard- und Touch-Controls

**Dateien:** src/App.vue, src/style.css

**Test:** Low ueberspringen, High unterrutschen, npm run build
### 4. handwenic/runner-visuals-v2

**Owner:** HandweNic

**Ziel:** Runner und Hindernisse werden visuell klarer.

**Aenderungen:** Runner-Figur, Laufpose, Slide-Pose, Gate, Barrier, Cone, Crate

**Dateien:** src/App.vue

**Test:** Visuals und bestehende Kollisionen pruefen, npm run build
### 5. alireza/runner-polish-v2

**Owner:** alireza-553

**Ziel:** Runner bekommt mehr Feedback und Motivation.

**Aenderungen:** Combo, Multiplikator, Partikel, Feedback-Messages, Combo-HUD, Pacing-Anpassung

**Dateien:** src/App.vue, src/style.css

**Test:** Combo sammeln, Reset pruefen, Mobile HUD, npm run build
### 6. handwenic/neon-shooter-base-v2

**Owner:** HandweNic

**Ziel:** Bewusster Genre-Wechsel vom Runner zum Neon Shooter.

**Aenderungen:** Spieler-Schiff, freie Bewegung, Schuesse, Gegner, Waves, Powerups, Lives, Charge, Fire-Button

**Dateien:** src/App.vue, src/style.css

**Test:** Bewegen, schiessen, Gegner, Game Over, Powerups, npm run build
### 7. alireza/lan-player-relay-v2

**Owner:** alireza-553

**Ziel:** Erste LAN-Multiplayer-Grundlage.

**Aenderungen:** Player-ID, Remote-Spieler, Remote-Schuesse, Online/Mode-HUD, Vite WebSocket Relay

**Dateien:** src/App.vue, src/style.css, vite.config.js

**Test:** 2 Clients im WLAN, Online-Anzeige, Remote-Spieler, npm run build
### 8. handwenic/shared-enemy-world-v2

**Owner:** HandweNic

**Ziel:** Alle LAN-Spieler teilen dieselbe Gegnerwelt.

**Aenderungen:** Host-Wahl, hostPayload, applyWorld, normalisierte Entities, shooter:world Relay

**Dateien:** src/App.vue, vite.config.js

**Test:** 2 Clients, gleiche Gegner/Waves, Host-Wechsel, npm run build
### 9. alireza/lan-delay-polish-v2

**Owner:** alireza-553

**Ziel:** LAN-Sync fuehlt sich direkter an.

**Aenderungen:** NETWORK_SEND_INTERVAL, WORLD_SYNC_INTERVAL, shooter:player Einzelupdates, kuerzere stale-player Zeit

**Dateien:** src/App.vue, vite.config.js

**Test:** 2 Clients, Bewegungsdelay, Online cleanup, npm run build
### 10. handwenic/test-and-docs-v2

**Owner:** HandweNic

**Ziel:** Start, Build, Steuerung und LAN-Test werden dokumentiert.

**Aenderungen:** Lokaler Start, LAN-Start, Beispiel-IP, Steuerung, Multiplayer-Testplan

**Dateien:** README.md

**Test:** README nachvollziehen, npm run build

