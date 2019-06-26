#!/usr/bin/env ruby

require 'optparse'

# defined option
OptionParser.new do |opts|
  opts.banner = '时间戳修复v0.0.1'

  # opts.on('-v', '--version', 'time code format version 1|2') do |value|
  #   $format = value
  # end

  opts.on('-i filename', '--input filename', 'Input file name') do |value|
    $input = value
  end

  opts.on('-o filename', '--output filename', 'Output file name') do |value|
    $output = value
  end

  $help = opts
end.parse!

# check and read option
options = {format: $format, input: $input, output: $output}
unless options[:input]
  puts $help
  #puts 'Run ./tcSort.rb -h for a list of options.'
  exit
end
unless File.exist?(options[:input])
  puts '[error]: input file not exist.'
  exit
end

`ffprobe -show_streams -select_streams v -show_entries packet=pts -of compact=p=0:nk=1 #{options[:input]} > #{options[:input]}.txt`

timecodes = []
threshold = 50000
empty_line = 0
File.open(options[:input]+".txt").each_line do |line|
  if line == "\n"
    empty_line += 1
    next
  end
  if line =~ /\d\|.+/
    next
  end
  timecodes.append(line.to_i)
end

puts "timecodes length: #{timecodes.length}"
puts "empty line: #{empty_line}"
#pp timecodes[0..10]

begin_tc = 0
last_tc = nil
list = []
# sort
timecodes.length.times do |index|
  if index == 0
    next
  end
  last_tc = index - 1
  if (timecodes[index]-timecodes[last_tc]).abs > threshold
    puts "[#{begin_tc}, #{last_tc}]"
    list.append("#{begin_tc}|#{last_tc}")
    timecodes[begin_tc..last_tc] = timecodes[begin_tc..last_tc].sort
    begin_tc = index
  end
end
last_tc += 1
puts "[#{begin_tc}, #{last_tc}]"
list.append("#{begin_tc}|#{last_tc}")
timecodes[begin_tc..last_tc] = timecodes[begin_tc..last_tc].sort
puts "timecodes length: #{timecodes.length}"
#pp timecodes[0..10]
list.each do |index|
  a, b = index.split("|")
  if a == "0"
    v = timecodes[a.to_i]
    timecodes[a.to_i..b.to_i] = timecodes[a.to_i..b.to_i].map{ |line| line - v }
  else
    v = timecodes[a.to_i]
    w = timecodes[a.to_i-1] + (timecodes[a.to_i-1]-timecodes[a.to_i-2])
    timecodes[a.to_i..b.to_i] = timecodes[a.to_i..b.to_i].map{ |line| line - v + w}
  end
end


unless options[:output]
  options[:output] = options[:input].split(".")[0..-2].join(".")+"-sort.txt"
end
if File.exist?(options[:output])
  print "File #{options[:output]} already exists. Overwrite ? [y/N] "
  unless gets.strip.downcase == "y"
    puts "Not overwriting - exiting"
    exit
  end
end
File.open(options[:output], mode="w") do |f|
  # case options[:format]
  # when "v2"
  #   out.each do |line|
  #     f.write(line+"\n")
  #   end
  # when "v1"
  #   out.each do |line|
  #     if line =~ /format/
  #       f.write(line+"\n")
  #       next
  #     end
  #     f.write(sprintf("%.15g",line)+"\n")
  #   end
  # end
  timecodes.each do |line|
    f.write(line.to_s+"\n")
  end
end
puts "Save result as #{options[:output]}"
