# frozen_string_literal: true

class Rogare::Commands::Hello
  extend Rogare::Command

  command 'hello', hidden: true

  match_command /.+/, method: :execute
  match_empty :execute
  def execute(m)
    this_server = m.channel.server
    servers, needs_prefix = if this_server
                              [{ 0 => this_server }, false]
                            else
                              [Rogare.discord.servers, true]
                            end

    servers.each do |_id, server|
      if ENV['RACK_ENV'] == 'production' && server.name == 'sassbot-test'
        logs 'skip sassbot test server in production'
        next
      end

      member = m.user.discord.on(server)
      person = server.roles.find { |role| role.name == 'person' }
      prefix = ("[**#{server.name}**]" if needs_prefix)

      unless person
        m.reply "No **person** role on #{prefix || 'here'}, tell the server admins!"
        next
      end

      begin
        if member.roles.any? { |role| role.id == person.id }
          if needs_prefix
            m.reply "#{prefix} You’re already all good here, but thanks for saying hi."
          else
            m.reply 'You can already speak in here! And hello to you too'
          end
        else
          member.add_role(person, 'Said hello to the bot')
          m.reply "#{prefix} You may speak! Thank you! Enjoy yourself!"
        end
      rescue StandardError => e
        m.reply "Something went wrong! Tell the #{prefix} admins!"
        logs "!!! Missing role-management permissions for #{server.name}???\n#{e}"
      end
    end
  end
end
