require 'cinch'

module Bradford
  class StatusBot
    include Cinch::Plugin

    match /.*status-bot.*undo;.*/i, :method => :undo, :use_prefix => false
    match /.*status-bot.*post;(.+)/i, :method => :post, :use_prefix => false
    match /.*status-bot.*fault;(.+)/i, :method => :post, :use_prefix => false
    match /.*status-bot.*list;.*/i, :method => :list, :use_prefix => false
    match /.*status-bot.*expire;(.+)/i, :method => :expire, :use_prefix => false
    match /.*status-bot.*help;.*/i, :method => :help, :use_prefix => false

    def self.run!
      bot = Cinch::Bot.new do
        configure do |c|
          c.nick = "status-bot"
          c.server = "irc.yourserver.com"
          c.port = 9999
          c.password = "password"
          c.ssl.use = false
          c.realname = "Mr. Status"
          c.channels = ["#yourchannel channelpassword"]
          c.plugins.plugins = [StatusBot]
        end
      end
      bot.start
    end

    def initialize(*args)
      super
      @@last_message_id = nil
    end

    def post m, c
      @@last_message_id = Post.add_edit_post(copy: c, category: "fault")
      m.reply "OK, I posted that. Use 'undo;' if it was a mistake."
    end

    def undo m
      content = Post[@@last_message_id].delete
      m.reply "OK, I killed a post that started like this: #{content.markdown[0..30].gsub(/\s\w+$/, '...')}"
    end

    def list m
      c = Category.find(:name => "fault").first
      post_data = c.posts
      posts = {}
      post_data.each do |p|
        unless p.expired?
          posts[p.id] = p.markdown[0..30].gsub(/\s\w+$/, '...')
        end
      end
      unless posts.length == 0
        m.reply "OK, here are the faults up right now:"
        posts.each_key do |k|
          m.reply "[#{k}] => #{posts[k]}"
        end
        m.reply "-- To expire a fault, use 'expire; ID'"
      else
        m.reply "No faults posted right now that I can see."
      end
    end

    def expire m, c
      p = Post[c.to_i]
      if p.nil?
        m.reply "Hmm...I couldn't find a post with that ID"
      else
        p.expire
        content = p.markdown
        m.reply "OK, I set a post to expire with this beginning: #{content[0..30].gsub(/\s\w+$/, '...')}"
      end
    end

    def help m
      m.reply "I'm a really stupid bot. I only pay attention to you if you mention me, and I know these comands:"
      m.reply "Make a new post: 'post; CONTENT'"
      m.reply "Undo the last post: 'undo;'"
      m.reply "List all posts: 'list;'"
      m.reply "Expire a post: 'expire; ID'"
    end

  end
end


