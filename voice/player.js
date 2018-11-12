const Discord = require('discord.js')
const readline = require('readline')
const client = new Discord.Client()

client.on('ready', waitForInstruction)
client.login(process.env.DISCORD_TOKEN)

function err (thing) {
  console.error(thing)
  return thing
}

function onho (...things) {
  console.error(...things)
  console.log(things.map(thing => `${thing}`).join(' '))
}

function waitForInstruction () {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
  });

  rl.on('line', (line) => followInstruction(line).catch(err))
  console.log('READY')
}

async function followInstruction (line) {
  line = line.trim()
  const [cmd, arg] = line.split(' ', 2)

  if (cmd == 'CONNECT') return connect(arg)
  if (cmd == 'DISCONNECT') return disconnect()
  if (cmd == 'PLAY') return perform(arg)
}

async function connect (scid) {
  const [sid, cid] = scid.split('/')
  console.error(`Sid: ${sid}, Cid: ${cid}`)

  const guild = client.guilds.get(sid)
  if (!guild) return ohno('No such server', sid)

  const chan = guild.channels.get(cid)
  if (!chan) return ohno('No such channel', cid)

  if (err(chan.type) !== 'voice') return ohno('Not a voice channel')

  await chan.join()
  console.log('CONNECTED')
}

function disconnect () {
  const voice = client.voiceConnections.first()
  voice.disconnect()
  console.log('DISCONNECTED')
}

async function perform (file) {
  const voice = client.voiceConnections.first()
  await voice.channel.guild.me.setMute(false)
  await sleep(1)
  const dispatch = await voice.playFile(`voice/${file}.mp3`)
  console.log('PLAYING')
  await sleep(1)
  await voice.channel.guild.me.setMute(true)
}

function sleep (secs) {
  return new Promise(done => setTimeout(done, secs * 1000))
}
