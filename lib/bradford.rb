require 'bundler/setup'
require 'bradford/app'
require 'bradford/model'
require 'bradford/bot'

module Bradford
  def self.setup
    Category.setup
  end
end
