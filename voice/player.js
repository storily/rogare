const Discord = require('discord.js')
const readline = require('readline')
const client = new Discord.Client()

client.on('ready', waitForInstruction)
client.login(process.env.DISCORD_TOKEN)

function waitForInstruction () {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
  });

  rl.on('line', followInstruction)
  console.log('READY')
}

function followInstruction (line) {
  line = line.trim()
  const [cmd, arg] = line.split(' ', 2)

  if (cmd == 'CONNECT') return connect(arg)
  if (cmd == 'PLAY') return perform(arg)
}

function connect (chan) {
  // console.log('NOT YET')
}

function perform (file) {
  console.log('TODO', `voice/${file}.mp3`)
}
