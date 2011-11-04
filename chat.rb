require 'rubygems'
require 'xmpp4r'
$sys_voice = false
$user_voice = true
$my_voice = "Vicki"
$your_voice = "Agnes"
VOICES = {"agnes" => "Agnes", "kathy" => "Kathy", "princess" => "Princess", "vicki" => "Vicki", "victoria" => "Victoria", "bruce" => "Bruce", "fred" => "Fred", "junior" => "Junior", "ralph" => "Ralph", "albert" => "Albert", "bad news" => "Bad News", "bahh" => "Bahh", "bells" => "Bells", "boing" => "Boing", "bubbles" => "Bubbles", "cellos" => "Cellos", "deranged" => "Deranged", "good news" => "Good News", "hysterical" => "Hysterical", "pipe organ" => "Pipe Organ", "trinoids" => "Trinoids", "whisper" => "Whisper", "zarvox" => "Zarvox"}

class Manager
  
  attr_accessor :jid, :cl
  
  def sign_in
    superputs "Great job! What is your username?", true
    username = supergets
    superputs "And what is your password?", true
    password = supergets
    superputs "I'm going to try signing you in now.", true
    @cl = nil
    while @cl.nil?
      begin
        @jid = Jabber::JID.new("#{username}@jabber.org")
        @cl = Jabber::Client.new(@jid)
        @cl.connect
        @cl.auth(password)
        @cl.send(Jabber::Presence.new.set_type(:available))
      rescue
        @cl = nil
        superputs "Great job! What is your username?", true
        username = supergets
        superputs "And what is your password?", true
        password = supergets
        superputs "I'm going to try signing you in now.", true
      end
    end
    show_management
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
  def show_management
    superputs "What would you like to do today, #{@jid.node}?", true
    # superputs "To see who else is online, type 'friends'."
    superputs "To see your settings and edit them, type 'settings'.", true
    superputs "To chat with people, type 'chat'", true
    superputs "To leave our wonderful universe, type 'exit' at any time.", true
    superputs "(No matter where you are in our program, you can always access these utilities by typing '()))' before any command)", true
    answer = supergets
    loop do
      run_command(answer)
      answer = supergets
    end
  end
  
  def run_command(answer)
    case answer
    # when "friends"
    #   show_friends
    when "settings"
      show_settings
    when "chat"
      partner = nil
      while partner.nil?
        superputs "Who do you want to chat with? Please enter a username.", true
        potential_partner = supergets
        superputs "You will enter chat with #{potential_partner}. Does this look right? (y/n)", true
        answer = supergets
        while !["y", "n"].include?(answer)
          superputs "Please try again...", true
          answer = supergets
        end
        partner = potential_partner if answer == "y"
      end
      chat_loop(partner)
    end
  end
  
  def chat_loop(user)
    @cl.add_message_callback do |m|
      case m.type
      when :chat
        if m.from.to_s.gsub(/@.*/, '').downcase == user.downcase
          Thread.new { message_puts m.body, user }.run
          print "(#{Time.now.strftime("%k:%M").strip}) \e[1m\e[34myou:\e[0m\e[0m "
          # @cl.send Jabber::Message.new("#{user}@jabber.org", "#{m.body}").set_type(:chat)
        end
      when :error
        puts "\n ERROR (#{user} MAYBE NOT AVAILABLE?)"
      else
        puts "recieved other kind of response..."
        puts m.inspect
      end
    end
    
    puts " (((  ) CHATTING WITH #{user.upcase} (((  ) "
    loop do
      print "(#{Time.now.strftime("%k:%M").strip}) \e[1m\e[34myou:\e[0m\e[0m "
      message = supergets.strip
      determine_function(message)
      message = "3t#{$your_voice}3t#{message.gsub("'", "\\'")}"
      puts message.inspect
      @cl.send Jabber::Message.new("#{user}@jabber.org", message).set_type(:chat)
      print "\n"
    end
    
    @cl.close
    
  end
  
  def determine_function(message)
    if message[0..8].downcase == "3t: voice" || message[0..10].downcase == "())): voice" || message[0..10].downcase == "(((): voice"
      voice
    elsif message[0..11].downcase == "3t: 43d3d3d3" || message[0..13].downcase == "())): 43d3d3d3" || message[0..13].downcase == "(((): 43d3d3d3"
      voice
    # elsif message[0..10].downcase == "3t: friends" || message[0..12].downcase == "())): friends" || message[0..12].downcase == "(((): friends"
    end
  end
  
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
    answer = gets
    puts "\t\t(GETS RECIEVES: #{answer})"
    if answer.strip.downcase == "exit"
      exit
    else
      return answer.strip.downcase
    end
  end
  
  def message_puts(content, user)
    puts "\n(#{Time.now.strftime("%k:%M").strip}) \e[1m\e[32m#{user}:\e[0m\e[0m #{content}"
    `say -v #{content.split("3t")[1]} '#{content.split("3t")[2]}'`
  end
end

m = Manager.new
m.startup