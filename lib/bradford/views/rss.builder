xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Bradford - The Status Board"
    xml.description "Bradford - The Status Board"
    xml.link request.url.chomp request.path_info
    Category.find(:prio => 1).first.posts.each do |post|
      unless post.expired?
        xml.item do
          xml.title post.markdown
          xml.link "#{request.url.chomp request.path_info}/"
          xml.guid "#{request.url.chomp request.path_info}/#{post.id}"
          xml.pubDate Time.parse(post.posted_at).rfc822
          xml.description post.markdown
        end
      end
    end
  end
end
