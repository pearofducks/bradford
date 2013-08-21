require 'ohm'
require 'redcarpet'
require 'yaml'

class Category < Ohm::Model
  attribute :name
  attribute :color
  attribute :prio
  attribute :full_title
  attribute :icon
  attribute :expiry_age

  index :name
  index :prio
  collection :posts, :Post

  def self.setup
    if Category.all.first.nil?
      config = YAML.load_file('categories.yml')
      category_data = config['Categories']
      category_data.map do |c|
        Category.create(
          name: c["Name"].downcase,
          color: c["Color"],
          prio: c["Prio"] || 0,
          full_title: c["Title"] || @name.capitalize,
          icon: c["Icon"],
          expiry_age: c["Expire"] || 3
        )
      end
    end
  end
end

class Post < Ohm::Model
  attribute :posted_at
  attribute :markdown
  attribute :expired_at

  reference :category, :Category

  def expire
    @attributes[:expired_at] = Time.new
    return self.save
  end

  def expired?
    @attributes[:expired_at] ? true : false
  end

  def self.add_edit_post vars
    p = Post[vars[:edit_id]] || Post.create(posted_at: Time.new)
    p.markdown = vars[:copy]
    c = Category.find(:name => vars[:category]).first
    if c.nil?
      return :no_category
    end
    p.category = c
    p.save ? p.id : :error
  end

  def retire_now?
    if expired?
      expiry_date = Time.parse(@attributes[:expired_at]) + (category.expiry_age.to_i*60*60*24)
      if Time.now > expiry_date
        self.delete
        return true
      end
    end
    return false
  end

  def html
    engine = Redcarpet::Markdown.new Redcarpet::Render::HTML, {:no_intra_emphasis=>true}
    engine.render(@attributes[:markdown])
  end
end
