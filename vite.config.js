import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// Kleiner LAN-Relay fuer den Vite-Dev-Server: Er verteilt Spieler-, Schuss-
// und Welt-Daten zwischen Browsern im gleichen Netzwerk.
function lanMultiplayerRelay() {
  // Merkt alle verbundenen Spieler und entfernt inaktive Spieler nach kurzer Zeit.
  const players = new Map()
  const stalePlayerMs = 2500
  let hostId = ''

  function electHost(server) {
    // Der erste aktive Spieler wird Host und darf die gemeinsame Gegner-Welt senden.
    if (hostId && players.has(hostId)) return
    hostId = players.keys().next().value || ''
    server.ws.send('shooter:host', { id: hostId })
  }

  function broadcastPlayers(server) {
    // Informiert alle Browser ueber aktuelle Spieler und den aktuellen Host.
    electHost(server)
    server.ws.send('shooter:players', [...players.values()])
    server.ws.send('shooter:host', { id: hostId })
  }

  return {
    name: 'lan-multiplayer-relay',
    configureServer(server) {
      // Spieler tritt bei und wird an alle Clients weitergegeben.
      server.ws.on('shooter:join', (player) => {
        players.set(player.id, { ...player, lastSeen: Date.now() })
        broadcastPlayers(server)
      })

      // Alte Positionsupdates bleiben fuer Kompatibilitaet erhalten.
      server.ws.on('shooter:update', (player) => {
        players.set(player.id, { ...player, lastSeen: Date.now() })
        broadcastPlayers(server)
      })

      // Schnelle Einzelspieler-Updates reduzieren sichtbare LAN-Verzoegerung.
      server.ws.on('shooter:player', (player) => {
        players.set(player.id, { ...player, lastSeen: Date.now() })
        server.ws.send('shooter:player', players.get(player.id))
      })

      // Schuesse werden sofort an alle anderen Clients verteilt.
      server.ws.on('shooter:shot', (shot) => {
        server.ws.send('shooter:shot', shot)
      })

      // Nur der Host darf Gegner, Powerups und Gegner-Schuesse synchronisieren.
      server.ws.on('shooter:world', (world) => {
        if (world.hostId === hostId) server.ws.send('shooter:world', world)
      })

      // Beim Verlassen wird der Spieler entfernt; falls es der Host war, wird neu gewaehlt.
      server.ws.on('shooter:leave', (player) => {
        players.delete(player.id)
        if (player.id === hostId) hostId = ''
        broadcastPlayers(server)
      })

      // Entfernt Spieler, die keine Updates mehr schicken, z. B. nach geschlossenem Tab.
      setInterval(() => {
        const now = Date.now()
        let changed = false
        for (const [id, player] of players) {
          if (now - player.lastSeen > stalePlayerMs) {
            players.delete(id)
            if (id === hostId) hostId = ''
            changed = true
          }
        }
        if (changed) broadcastPlayers(server)
      }, 900)
    },
  }
}

export default defineConfig(({ command }) => ({
  // GitHub Pages braucht beim Production-Build den Repository-Pfad als Base-URL.
  // Lokal bleibt die App unter "/" erreichbar.
  base: command === 'build' ? '/HandwerkEbadi-project/' : '/',
  plugins: [vue(), lanMultiplayerRelay()],
}))
