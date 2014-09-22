#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'

# Special characters are ok, but here are the RNS-E limits:
#
# * No more than 512 (400?) 'objects' in the filesystem
# * Pathnames no longer than 64 characters (including extension?)

source = ARGV[0]

if source.to_s == ''
  STDERR.puts "SOURCE and TARGET are required"
  exit 1
end

# data[album][artist] = [tracks]
data = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = [] } }

Dir['*.m3u'].each {|l| FileUtils.rm l }

Dir["#{source}/*"].each do |path|
  next unless File.directory?(path)

  artist = File.split(path).last

  Dir["#{source}/#{artist}/*"].each do |path|
    album = File.split(path).last

    data[album][artist] = Pathname.new(path).children.map(&:to_s).grep(/\.mp3$/)
  end
end

def shorten_track_name(path, prefix_length = 3)
  filename = File.basename(path)

  num, name = filename.match(/^(\d+) ?(.*)\.mp3/)[1..2]

  "#{num} #{name[0..(59 - prefix_length)]}.mp3"
end

def move_and_shorten_tracks(tracklist, target)
  tracklist.map do |track|
    shorten_track_name(track).tap do |name|
      #puts "Moved: #{track} to #{File.join(target, name)}"
      FileUtils.mv track, File.join(target, name)
    end
  end
end

def create_playlist(name, target, tracks)
  move_and_shorten_tracks(tracks, target).tap do |files|
    File.open("#{name}.m3u", 'w') do |out|
      files.each do |track|
        out.puts File.join(target, track)
      end
    end
  end
end

album_count = 0
data.each do |album, artists|
  album_target = "a#{album_count+=1}"
  FileUtils.mkdir_p(album_target)

  if artists.size == 1
    playlist = "#{artists.keys.first} - #{album}"

    if playlist.size > 60
      STDERR.puts "#{playlist} too long, shortening"
      
      playlist = "#{artists.keys.first} - #{album[0..(55 - artists.keys.first.size)]}"
    end

    create_playlist(playlist, album_target, artists.values.first.sort)
  else
    create_playlist(album, album_target, artists.values.flatten.sort_by {|file| File.split(file).last })
  end
end
