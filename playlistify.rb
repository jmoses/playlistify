#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'

#source = ARGV[0].to_s
#target = ARGV[1].to_s

#unless source != '' && target != ''
#  STDERR.puts "SOURCE and TARGET are required"
#  exit 1
#end

# data[album][artist] = [tracks]
data = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = [] } }


Dir['*.m3u'].each {|l| FileUtils.rm l }

Dir['*'].each do |artist|
  Dir["#{artist}/*"].each do |path|
    album = File.split(path).last

    data[album][artist] = Pathname.new(path).children.map(&:to_s).grep(/\.mp3$/)
  end
end

all = []
data.each do |album, artists|
  album = album[0..30].gsub(/(\[\])/, '')
  if artists.size == 1
    File.open("#{artists.keys.first} - #{album}.m3u", 'w') do |out|
      out.puts "#EXTM3U"

      artists.values.first.sort.each do |track|
        all << track
        out.puts track
      end
    end
  else
    File.open("#{album}.m3u", 'w') do |out|
      out.puts "#EXTM3U"

      artists.values.flatten.sort_by {|file| File.split(file).last }.each do |track|
        all << track
        out.puts track
      end
    end
  end
end

File.open('all.m3u', 'w') do |out|
  out.puts '#EXTM3U'
  all.each do |track|
    out.puts track
  end
end
