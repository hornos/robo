#!/usr/bin/env ruby
require 'mustache'
require 'name-generator'
require 'YAML'
require 'ERB'

require 'mechanize'
require 'open-uri'
require 'pry'


class Robache < Mustache
  attr_accessor :nick,:avatar,:nickname,:ng,:surname,:forname
  attr_accessor :password1, :password2, :password3
  attr_accessor :password4, :password5, :password6

  def initialize()
    begin
      @config = YAML.load(ERB.new(File.read(File.basename(__FILE__,".rb")+".yml")).result)
    rescue Exception => e
      STDERR.puts "pre #{e.message}"
    end

    @ng = NameGenerator::Main.new
    @nick = @ng.next_name
    @surname = @ng.next_name
    @forname = @ng.next_name
    @nickname = @forname.downcase.delete('aeiou') + @surname.downcase.delete('aeiou') + rand(100...1000).to_s
    @password1 = rand(2**256).to_s(36).ljust(8,'a')[0..16]
    @password2 = rand(2**256).to_s(36).ljust(8,'a')[0..16]
    @password3 = rand(2**256).to_s(36).ljust(8,'a')[0..16]
    @password4 = rand(2**256).to_s(36).ljust(8,'a')[0..16]
    @password5 = rand(2**256).to_s(36).ljust(8,'a')[0..16]
    @password6 = rand(2**256).to_s(36).ljust(8,'a')[0..16]

    if not @config[:avatars].nil?
      agent = Mechanize.new
      case
      when @config[:avatars][:tumblr]
        agent.get(@config[:avatars][:tumblr])
        a=agent.page.images_with(:src => %r{avatar.*.png}).map do |img|
          img.url.gsub!(/\_40\./,"_128.")
        end.compact.to_a
      end
      @avatar = a[rand(1..a.size)]
      # todo avatar curl
    end
  end
end

r = Robache.new
puts r.render
