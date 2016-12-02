require 'discordrb'
require 'uri'
require 'yaml'
require 'rubygems'
require 'open-uri'
require 'simple-rss'
require 'open3'
require 'markov_chain_chat_bot'
require 'hummingbirdme'
require 'json'

hbird = Hummingbirdme

config = YAML.load_file("config.yml")

owner_id = config["login"]["owner_id"]
bot_id = config["login"]["bot_id"]
app_id = config["login"]["app_id"]
prefix = config["main"]["prefix"]
whitelist = File.open("whitelist", "rb").read

get_time = Time.now
uptime_base = get_time
fm = ""

markov = MarkovChainChatBot.from(Hash.new)
learn_data = File.open("markov.txt", "rb").read
learn_array = learn_data.split("\n")
learn_array.each { |x| markov.learn(x) }

bot = Discordrb::Commands::CommandBot.new token: config["login"]["bot_token"], client_id: bot_id, prefix: prefix

bot.command :amai do |event|
  "TripingPC, the dev for Nemi and Amai has given up on trying to maintain two bots at once.  The developer panel application for Amai will be removed on February 3rd 2016.  Please make sure to tell server admins you know of that use Amai that they should switch to this bot..  Most features from Amai will be ported over to Nemi."
end

bot.command :delete do |event, id|
  if id == ""
    msg_arr = event.channel.history(1)
	msg_arr
	if msg_arr[0].author.id == bot_id
	  msg_arr[0].delete
	  break
	end
  end
  event.channel.load_message(id).delete
end

bot.command :info do |event|
  "For more info go to http://tripin.gq/nemi"
end

bot.command :anime do |event, *str|
   str = str.join(" ")
   str = str.downcase.gsub(/[^a-z0-9\s]/i, '')
   str = str.tr(" ", "-")

   if str == "cory-in-the-house"
     event.respond "Here, have this ~~you dumdum living meme.~~\n http://imdb.com/title/tt0805815"
	 break
   elsif str.include? "fresh-prince"
     event.respond "You disappoint me greatly...  Well whatever, you asked for it.\n http://imdb.com/title/tt0098800"
	 break
   end
   
   search_messages = ["I'm searching through the massive Hummingbird library.  gimme a moment...",
   "Contacting the almighty anime gods for knowledge.",
   "Extrapolating splines at hbird.api.v8345.36.4633 endpoints.  ~~beep boop~~",
   "I mean, I really hope you didn't make an obvious typo or whatever...",
   "Uhmm, let's see...",
   "Just skimming over rapidly, I don't see any results, but let's look better!"]
   
   fail_messages = ["I didn't find anything, you sure you didn't type it out wrong?",
   "Welp, nothing here...  Maybe use Google instead? ~~or Bing~~...",
   "The detectives tell me there are no evidences on the scene.  Too bad heh."]
   
   m = event.respond search_messages.sample
   
   anime = hbird.anime(str)
   
   if anime.length < 6
     m.edit fail_messages.sample
   else
     short_syn = anime["synopsis"].split(". ")
     short_syn_str = "#{short_syn[1]} #{short_syn[2]} #{short_syn[3]}..."
	 m.edit "I found this, I hope it's the right one...\n\n**#{anime["title"]}**\nSynopsis: #{short_syn_str}\nAired on #{anime["started_airing"]}\n#{anime["cover_image"]}"
   end
end

bot.message(start_with: "nemi, ") do |event|
  input = event.message.content[6..-1]
  markov.learn(input)
  learn_data = "#{learn_data}\n#{input}"
  File.open("markov.txt", 'w') { |file| file.write(learn_data) }
  event.respond "​#{(markov.answer(input))}"
end

bot.command :whitelist do |event, action, mention|
  message = ""
  if mention.include? "@"
    mention = mention[2..-1].chomp(">").to_s
  end
  current_user = event.server.member(mention)
  if event.author.id == owner_id
    if action == "add"
      if whitelist.include? mention
        message = "#{current_user.display_name} is already in the whitelist."
        nil
      else
        whitelist = "#{whitelist}#{mention} "
        message = "Added #{current_user.display_name} to the whitelist."
        nil
      end
    elsif action == "remove"
      if whitelist.include? mention
        whitelist.slice! mention
        message = "#{current_user.display_name} was removed from the whitelist."
        nil 
      else
        message = "#{current_user.display_name} is not in the whitelist."
        nil
      end
    end
    File.open("whitelist", 'w') { |file| file.write(whitelist) }
    nil
  end
  message
end

bot.command :help do |event, *search|
  do_tags = false
  search = search.join(" ")
  if search.include? "--tags"
    do_tags = true
	search = search.chomp(" --tags")
  end
  stdout, stdeerr, status = Open3.capture3("cat help | grep -i #{search}")
  if stdout.length < 3
    "Invalid search.  For a list of all the commands go to http://tripin.gq/nemi/help"
  elsif search.length < 1
    "For the full list of commands and their usage, go to http://tripin.gq/nemi/help"
  elsif do_tags == false
    help_obj = stdout.split("|")
    "**#{help_obj[0]}** `Available to: #{help_obj[3]}`\n\n#{help_obj[1]}"
  elsif do_tags == true
    help_obj = stdout.split("|")
    "**#{help_obj[0]}** `Available to: #{help_obj[3]}`\n\n#{help_obj[1]}\n\n Tags: *#{help_obj[2]}*"
  end
end

bot.command :say do |event, *message|
  message = message.join(" ")
  if event.author.id == owner_id or whitelist.include? event.author.id.to_s
    message
  end
end

bot.command :ping do |event|
  t = Time.now - event.timestamp
  s = t * 100.0
  p = s.round(2)
  "```xl\n#{p} Miliseconds```"
end

bot.command :nameset do |event, *name|
  if event.author.id == owner_id
    name = name.join(" ")
    bot.profile.username = name
    bot.profile.avatar = (File.new("avatar.png"))
    return "I am now called #{name}!"
  end
  nil
end

bot.command :moe do |event|
  rss = SimpleRSS.parse open("http://e-shuushuu.net/index.rss")
  rss.items.first.link
end

bot.command :invite do |event|
  "Add me to your server. https://discordapp.com/oauth2/authorize?&client_id=#{app_id}&scope=bot&permissions=0"
end

bot.command(:"ix.io") do |event, action, *str|
  str = str.join(" ")
  if action == "upload"
    begin
      stdout, stdeerr, status = Open3.capture3("echo #{str} | curl -F 'f:1=<-' ix.io")
      stdout
    rescue => e
      "Something went wrong."
    end
  elsif action == "get"
    Net::HTTP.get(URI.parse(str))
  elsif action == "download"
    system("curl -O #{str}")
    event.channel.send_file(File.new("#{str[13..-1]}"))
    system("rm #{str[13..-1]}")
    nil
  end
end

bot.command :sys do |event, *str|
  str = str.join(" ")
  if event.author.id == owner_id or (whitelist.include? event.author.id.to_s)
    begin
      stdout, stdeerr, status = Open3.capture3(str)
      "```#{stdout}```"
    rescue => e
      "```#{e}```"
    end
  end
end

bot.command :eval do |event, *str|
  str = str.join(" ")
  if event.author.id == owner_id or whitelist.include? event.author.id.to_s
    begin
      eval(str).to_s
    rescue => e
      e
    end
  end
end

bot.command :twitter do |event, user|
  rss = SimpleRSS.parse open("https://queryfeed.net/twitter?q=from%3A#{user}&title-type=tweet-text-full&geocode=&omit-retweets=on&attach=on")
  rss.items.first.link
end

bot.command :guilds do |event|
  "I am in #{bot.servers.length} guilds and I've seen a whopping #{bot.users.length} users!"
end

bot.command :gameset do |event, *str|
  if event.author.id == owner_id
    bot.game = str.join(" ")
    "Sure thing!"
  else
    'Nah, I have better things to do.'
  end
end

bot.command :shutdown do |event|
  if event.author.id == owner_id
    exec "exit"
    exec 'echo Bot terminated by dev.'
  else
    nil
  end
end

bot.command :mariomaker do |event, *str|
  course_tag = ''
  course_id = str.join(" ")
  if course_id.length > 19 or course_id.length < 19 or !course_id.include? '-0000-'
    "Invalid course ID."
  else
    system "wget https://supermariomakerbookmark.nintendo.net/courses/#{course_id}"
    course_page = File.open("#{course_id}", "rb")
    course_html = course_page.read
    system "wget https://dypqnhofrd2x2.cloudfront.net/#{course_id}_full.jpg"
    if course_html.include? 'course-tag radius5">Traditional'
      course_tag = 'Traditional'
    elsif course_html.include? 'course-tag radius5">Track'
      course_tag = 'Track'
    elsif course_html.include? 'course-tag radius5">Shoot-'
      course_tag = "Shoot-'em-up"
    elsif course_html.include? 'course-tag radius5">Autoscroll'
      course_tag = 'Autoscroll'
    elsif course_html.include? 'course-tag radius5">Speedrun'
      course_tag = 'Speedrun'
    elsif course_html.include? 'course-tag radius5">Theme'
      course_tag = 'Theme'
    elsif course_html.include? 'course-tag radius5">Yoshi'
      course_tag = 'Yoshi'
    elsif course_html.include? 'course-tag radius5">Costume'
      course_tag = 'Costume'
    elsif course_html.include? 'course-tag radius5">Thumbnail'
      course_tag = 'Thumbnail'
    elsif course_html.include? 'course-tag radius5">Remix'
      course_tag = 'Remix'
    elsif course_html.include? 'course-tag radius5">Dash'
      course_tag = 'Dash'
    elsif course_html.include? 'course-tag radius5">Gimmick'
      course_tag =  'Gimmick'
    elsif course_html.include? 'course-tag radius5">Puzzle'
      course_tag = 'Puzzle'
    elsif course_html.include? 'course-tag radius5">Music'
      course_tag = 'Music'
    elsif course_html.include? 'course-tag radius5">Automatic'
      course_tag = 'Tag: **Automatic**'
    else
      course_tag = '(None)'
    end
	
	upload_caption = "Requested by: **#{event.author.display_name} (#{event.author.name})**\nCourse ID: **#{course_id}**\nLink: **https://supermariomakerbookmark.nintendo.net/courses/#{course_id}**\nTag: **#{course_tag}**"
	
	event.channel.send_file((File.new("#{course_id}_full.jpg", "rb")), caption: upload_caption)
    system "rm #{course_id} #{course_id}_full.jpg"
	nil
  end
end

bot.command :uptime do |event|
  uptime = Time.now - uptime_base
  formatted_uptime = Time.at(uptime).utc.strftime("```xl\nmy uptime is: %H Hours, %M Minutes, and %S Seconds\nthe unformatted uptime is #{uptime} Seconds.```")
  "#{formatted_uptime}"
end

bot.run
