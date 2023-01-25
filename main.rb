#!/bin/ruby

require 'rss'
require 'open-uri'
require 'discordrb'
require 'nokogiri'
$url = 'https://news.ycombinator.com/rss'

bot     = Discordrb::Bot.new token: File.open('keys').readlines.map(&:chomp)[0]
bot.run :async

server  = bot.servers.select { |id,server| server.name=="Szakkör" }.values[0]
channel = server.channels.select{|n| n.name == 'test' }[0]

puts "We got everything!"

def get_news
  URI.open($url) { |rss|
    RSS::Parser.parse(rss)
               .items
               .each_with_object(Hash.new(0)) { |item,hash| hash[item.title] = { :link     => item.link,
                                                                                 :comments => item.comments,
                                                                                 :date     => item.pubDate } } }
end

$db = {}

loop do
  new = get_news
  ($db.keys & new.keys).each { |n| new.delete(n) }
  new.each do |k,v|
    image = URI.open(v[:link]) do |website|
      x = Nokogiri::HTML(website).at('meta[property="og:image"]')
      x.attributes['content'].value if !(x.nil?)
    end
    puts image
    puts 
    channel.send_embed do |embed|
      embed.title     = k
      embed.image     = Discordrb::Webhooks::EmbedImage.new url: ((image[..1] != './' )? image : v[:link] + image[2..]) if !(image.nil?)
      embed.footer    = Discordrb::Webhooks::EmbedFooter.new    icon_url: "https://news.ycombinator.com/y18.gif", text: "HackerNews"
      embed.fields    = [Discordrb::Webhooks::EmbedField.new(name: '', value: "[Website](#{v[:link]})", inline: true),
                         Discordrb::Webhooks::EmbedField.new(name: '', value: "[Comments](#{v[:comments]})", inline: true)]
      embed.color     = "#ff5600"
      sleep 0.5
    end
    puts k
  end
  $db.merge(new)
  puts 'Sleeping 10 seconds!'
  sleep 60
end
