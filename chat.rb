require 'rubygems'
require 'xmpp4r'

VOICES = ["agnes", "kathy", "princess", "vicki", "victoria", "bruce", "fred", "junior", "ralph", "albert", "bad news", "bahh", "bells", "boing", "bubbles", "cellos", "deranged", "good news", "hysterical", "pipe organ", "trinoids", "whisper", "zarvox"]
CMD_REGEX = /^3t\/(.*)\//
CMD = "3t/"
SUBS = {
         /\(\(\(\s*\)/ => "a 3t",
         /\(\s*\)\)\)/ => "a 3t",
         /\(\s*\)\)/ => "balls",
         /\(\(\s*\)/ => "balls",
         /:[\s-]?\)/ => "happy",
         /:[\s-]?\D/ => "very happy",
         /:'?[\s-]?\(/ => "sad",
       }

$sys_voice = false
$user_voice = true
$my_voice = "Vicki"
$your_voice = "Agnes"

class Manager

  attr_accessor :jid, :cl

  def go
    sign_in(ARGV[0], ARGV[1])
    enter_console
  end

  def sign_in(username=nil,password=nil)
    while username.nil? || password.nil? || @cl.nil?
      username ||= get_answer("What is your username?")
      password ||= get_answer("And what is your username?")
      superputs "I'm going to try signing you in now.", true
      begin
        @jid = Jabber::JID.new("#{username}@jabber.org")
        @cl = Jabber::Client.new(@jid)
        @cl.connect
        @cl.auth(password)
        break if @cl.is_connected?
      rescue
        superputs "I am so sorry. I am having trouble connecting. Let's try again."
        @cl = nil
        username = nil
        password = nil
      end
    end
    @cl.send(Jabber::Presence.new.set_type(:available))
  end

  def get_answer(q)
    superputs q, true
    print "> "
    return supergets
  end

  def enter_console
    # superputs "To see who else is online, type 'friends'."
    superputs "To see your settings and edit them, type 'settings'.", true
    superputs "To chat with people, type 'chat'", true
    superputs "To leave our wonderful universe, type 'exit' at any time.", true
    superputs "(No matter where you are in our program, you can always access these utilities by typing '()))' before any command)", true
    action = get_answer("What would you like to do today, #{@jid.node}?")
    loop do
      run_command(action)
      action = get_answer("What would you like to do today, #{@jid.node}?")
    end
  end

  def run_command(answer)
    case answer
    # when "friends"
    #   show_friends
    when "settings"
      show_settings
    when "chat"
      okay = nil
      while okay != "y"
        partner = get_answer("Who do you want to chat with? Please enter a username.")
        okay = get_answer("You will enter chat with #{partner}. Does this look right? (y/n)")
        while !["y", "n"].include?(okay)
          okay = get_answer("Please try again...")
        end
      end
      chat_loop(partner)
    else
      superputs "I'm sorry, I didn't understand that.", true
    end
  end

  def show_settings
    superputs "SETTINGS!"
    superputs "To change your voice, type 'voice'", true
    superputs "To change my voice, type '4d3d3d3'", true
    superputs "When you are done here, type 'done'", true
    answer = supergets
    while answer != "done"
      if answer == 'voice'
        voice(answer)
      elsif answer == '4d3d3d3'
        fourd3d3d3(answer)
      end
    end
  end

  def voice
    previous_voice = $voice
    superputs 'What do you want to sound like? (Choose from Agnes, Kathy, Princess, Vicki, Victoria, Bruce, Fred, Junior, Ralph, Albert, "Bad News", Bahh, Bells, Boing, Bubbles, Cellos, Deranged, "Good News", Hysterical, "Pipe Organ", Trinoids, Whisper, Zarvox)', true
    answer = supergets
    while !VOICES.keys.include?(answer)
      superputs "Please try to change your voice again.", true
      answer = supergets
    end
    $your_voice = VOICES[answer]
    superputs "Your voice is now #{answer}. Do you think this is a good voice to use? (y/n)", true
    while !["y", "n"].include?(answer)
      superputs "I really want to know how you feel about how you sound.", true
      answer = supergets
    end
    if answer == "n"
      superputs "Ok. I am now going to change your voice back to your previous voice.", true
      $your_voice = previous_voice
    end
  end

  def fourd3d3d3
    previous_voice = $voice
    superputs 'What do you want me to sound like? (Choose from Agnes, Kathy, Princess, Vicki, Victoria, Bruce, Fred, Junior, Ralph, Albert, "Bad News", Bahh, Bells, Boing, Bubbles, Cellos, Deranged, "Good News", Hysterical, "Pipe Organ", Trinoids, Whisper, Zarvox)', true
    answer = supergets
    while !VOICES.keys.include?(answer)
      superputs "Please try to change my voice again.", true
      answer = supergets
    end
    $my_voice = VOICES[answer]
    superputs "My voice is now #{answer}. Do you like how I sound? (y/n)", true
    while !["y", "n"].include?(answer)
      superputs "I really want to know how you feel about how I sound.", true
      answer = supergets
    end
    if answer == "n"
      superputs "Ok. I am now going to change my voice back to my previous voice.", true
      $my_voice = previous_voice
      superputs "I now sound like this.", true
    end
  end

  def chat_loop(user)
    @cl.add_message_callback do |m|
      case m.type
      when :chat
        if m.from.to_s.gsub(/@.*/, '').downcase == user.downcase
          voice, body = parse_message(m.body.to_s)
          message_puts(body, user)
          user_say(body, voice)
          print "(#{Time.now.strftime("%k:%M").strip}) \e[1m\e[34myou:\e[0m\e[0m "
        end
      when :error
        puts "\n ERROR (#{user} MAYBE NOT AVAILABLE?)"
      else
        puts "received other kind of response..."
        puts m.inspect
      end
    end

    puts " (((  ) CHATTING WITH #{user.upcase} (((  ) "
    loop do
      print "(#{Time.now.strftime("%k:%M").strip}) \e[1m\e[34myou:\e[0m\e[0m "
      message = supergets.strip
      # if message[0,CMD.length] == CMD
      cmd, msg = parse_input(message)
      case cmd
      when /help/
        puts "YOU NEED HELP!"
      when /voice=*+/
        $your_voice = cmd.gsub("voice=",'')
      when /voices/
        puts VOICES.inspect
      when nil
        message = "3t/#{$your_voice}/#{message}"
        @cl.send Jabber::Message.new("#{user}@jabber.org", message).set_type(:chat)
      else
        message = "3t/#{cmd}/#{message}"
        @cl.send Jabber::Message.new("#{user}@jabber.org", message).set_type(:chat)
      end

      # determine_function(message)
      # show the following:
      # > 3t/help
      # say in certain voice with out setting voice:
      # > 3t/<voice>/ hello
      # set voice:
      # > 3t/voice=<voice>
      # show voices:
      # > 3t/voices
      print "\n"
    end

    @cl.close

  end

  def parse_input(i)
    cmd = i.scan(/^#{CMD}([\w\s]*)/).flatten.first
    msg = i.gsub(/^#{CMD}([\w\s]*)\/?/,'').strip
    return cmd, msg
  end

  def parse_message(m)
    # maybe can understand other commands, not just voice?
    voice = m.scan(CMD_REGEX).flatten.first
    # puts commands.inspect
    body = m.gsub(CMD_REGEX,'')
    return voice, body
  end

  def escape_for_say(s)
    s.gsub(/\\*'/, "\\'")
  end

  def user_say(body, voice=$user_voice)
    Thread.new { `say -v '#{voice}' '#{escape_for_say(body)}'` }.run
  end

  def message_puts(body, user)
    puts "\n(#{Time.now.strftime("%k:%M").strip}) \e[1m\e[32m#{user}:\e[0m\e[0m #{body}\n"
    # Thread.new { `say -v '#{content.split("3t")[1]}' '#{content.split("3t")[2]}'` }.run
  end

  def determine_function(message)
    if message[0..8].downcase == "3t: voice" || message[0..10].downcase == "())): voice" || message[0..10].downcase == "(((): voice"
      voice
    elsif message[0..11].downcase == "3t: 4d3d3d3" || message[0..13].downcase == "())): 4d3d3d3" || message[0..13].downcase == "(((): 4d3d3d3"
      fourd3d3d3
    # elsif message[0..10].downcase == "3t: friends" || message[0..12].downcase == "())): friends" || message[0..12].downcase == "(((): friends"
    end
  end

  def superputs(content, system=false)
    if system
      puts content
      `say -v #{$my_voice} '#{content.gsub("'", "").gsub(")", "\)").gsub("(", "\(").gsub("()))", " 3t ")}'` if $sys_voice == true
    else
      puts content
      `say -v #{$my_voice} '#{content.gsub("'", "").gsub(")", "\)").gsub("(", "\(").gsub("()))", " 3t ")}'` if $user_voice == true
    end
  end

  def supergets
    STDIN.flush
    STDOUT.flush
    answer = STDIN.gets.strip
    # puts "\t\t(GETS RECIEVES: #{answer.inspect})"
    if answer.downcase == "exit"
      exit
    else
      return answer.downcase
    end
  end

  def make_subs(s)
    s = SUBS.inject(s) {|s,sub| s.gsub(sub[0],sub[1]) }
  end

  ## this is totally useless
  def startup
    superputs "Hello user at #{`hostname`}! So great to have you on our wonderful chat program. May I sign you in? (y/n)", true
    answer = supergets
    while !["y","n"].include?(answer.strip.downcase)
      superputs "Sorry, try again.", true
      answer = supergets
    end
    if answer.strip.downcase == "y"
      sign_in
    end
  end
  ######

end

m = Manager.new
m.go
