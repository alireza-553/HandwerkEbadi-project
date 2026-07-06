import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

function lanMultiplayerRelay() {
  const players = new Map()
  const stalePlayerMs = 2500
  let hostId = ''

  function electHost(server) {
    if (hostId && players.has(hostId)) return
    hostId = players.keys().next().value || ''
    server.ws.send('shooter:host', { id: hostId })
  }

  function broadcastPlayers(server) {
    electHost(server)
    server.ws.send('shooter:players', [...players.values()])
    server.ws.send('shooter:host', { id: hostId })
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

      server.ws.on('shooter:player', (player) => {
        players.set(player.id, { ...player, lastSeen: Date.now() })
        server.ws.send('shooter:player', players.get(player.id))
      })

      server.ws.on('shooter:shot', (shot) => {
        server.ws.send('shooter:shot', shot)
      })

      server.ws.on('shooter:world', (world) => {
        if (world.hostId === hostId) server.ws.send('shooter:world', world)
      })

      server.ws.on('shooter:leave', (player) => {
        players.delete(player.id)
        if (player.id === hostId) hostId = ''
        broadcastPlayers(server)
      })

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
  base: command === 'build' ? '/HandwerkEbadi-project/' : '/',
  plugins: [vue(), lanMultiplayerRelay()],
}))
