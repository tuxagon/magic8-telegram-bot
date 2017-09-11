require 'cgi'
require 'json'
require 'net/http'
require 'ostruct'
require 'uri'

class Config
  @@config = nil

  def self.get(key)
    load if @@config.nil?
    @@config[key.to_sym]
  end

  def self.load()
    json = JSON.parse(File.read('telegram.config'))
    @@config = json.reduce({}) do |h, (k,v)| 
      h[k.to_sym] = v
      h
    end
  end
end

class Telegram
  def initialize
    @token = Config.get(:token).freeze
    @url = "https://api.telegram.org/bot#{@token}".freeze
    @timeout = 100
  end

  def get_updates(offset = nil)
    query = ["timeout=#{@timeout}"]
    query.push("offset=#{offset}") if offset
    get_data("/getUpdates?#{query.join('&')}")
  end

  def send_message(text, chat)
    text = CGI.escape(text)
    get_data("/sendMessage?text=#{text}&chat_id=#{chat}")
  end

  def get_data(path)
    url = urlify(path)
    puts "GET #{url}"
    data = send(url)
    JSON.parse(data)
  end

  def send(url)
    Net::HTTP.get_response(url).body
  end

  def urlify(path)
    URI(@url + path.to_s)
  end

  private :urlify, :send, :get_data
end

class Magic8Bot
  COMMANDS = {
    '/shake' => :shake
  }.freeze
  NO_QUESTION = 'I\'m a fortune-teller, not a mind-reader. '\
    'What\'s your question?'.freeze
  ANSWERS = [
    'It is certain',
    'It is decidedly so',
    'Without a doubt',
    'Yes definitely',
    'You may rely on it',
    'As I see it, yes',
    'Most likely',
    'Outlook good',
    'Yes',
    'Signs point to yes',
    'Reply hazy try again',
    'Ask again later',
    'Better not tell you now',
    'Cannot predict now',
    'Concentrate and ask again',
    'Don\'t count on it',
    'My reply is no',
    'My sources say no',
    'Outlook not so good',
    'Very doubtful'
  ].freeze

  def initialize
    @telegram = Telegram.new
  end

  def run()
    last_update_id = nil
    loop do
      updates = @telegram.get_updates(last_update_id)
      unless updates['result'].empty?
        last_update_id = get_last_update_id(updates) + 1
        parse_commands(updates)
      end
      sleep(0.5)
    end
  end

  def get_last_update_id(updates)
    updates['result'].map do |u|
      u['update_id'].to_i
    end.max
  end

  def parse_commands(updates)
    updates['result'].each do |u|
      next if u['message'].nil? # only works for new messages
      msg = parse_message(u)
      next if msg.text.nil?
      COMMANDS.each do |cmd, func|
        send(func, msg, cmd) if msg.text.downcase.start_with?(cmd)
      end
    end
  end

  def shake(message, cmd)
    text = message.text.sub(cmd, '').strip
    ans = NO_QUESTION
    if text.end_with?('?') && text.length > 1
      ans = ANSWERS[(rand * ANSWERS.length).to_i]
    end
    @telegram.send_message(ans, message.chat_id)
  end

  def parse_message(update)
    OpenStruct.new(
      chat_id: update['message']['chat']['id'],
      text: update['message']['text']
    )
  end

  private :parse_message
end

Magic8Bot.new.run
