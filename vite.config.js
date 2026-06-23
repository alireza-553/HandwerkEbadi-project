import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

function lanMultiplayerRelay() {
  const players = new Map()

  function broadcastPlayers(server) {
    server.ws.send('shooter:players', [...players.values()])
  }

  return {
    name: 'lan-multiplayer-relay',
    configureServer(server) {
      server.ws.on('shooter:join', (player) => {
        players.set(player.id, { ...player, lastSeen: Date.now() })
        broadcastPlayers(server)
      })

      server.ws.on('shooter:update', (player) => {
        players.set(player.id, { ...player, lastSeen: Date.now() })
        broadcastPlayers(server)
      })

      server.ws.on('shooter:shot', (shot) => {
        server.ws.send('shooter:shot', shot)
      })

      server.ws.on('shooter:leave', (player) => {
        players.delete(player.id)
        broadcastPlayers(server)
      })

      setInterval(() => {
        const now = Date.now()
        let changed = false
        for (const [id, player] of players) {
          if (now - player.lastSeen > 4000) {
            players.delete(id)
            changed = true
          }
        }
        if (changed) broadcastPlayers(server)
      }, 1500)
    },
  }
}

export default defineConfig({
  plugins: [vue(), lanMultiplayerRelay()],
})
