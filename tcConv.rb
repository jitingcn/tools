#!/usr/bin/env ruby

require 'optparse'

OptionParser.new do |opts|
  opts.banner = 'Timecodes converter.'

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
options = {format: $format, input: $input, output: $output}
unless options[:input]
  puts $help
  #puts 'Run ./tcConv.rb -h for a list of options.'
  exit
end
unless File.exist?(options[:input])
  puts '[error]: input file not exist.'
  exit
end
tc = File.open(options[:input]).each_line.to_a.map{ |line|
  if line =~ /# timecode format+/
    options[:format]="tc1"
    next
  end
  if line =~ /Assume+/
    options[:format]="tc2"
    next
  end
  line = line.strip.split","
  if line.length == 3
    line = line[0].to_i, line[1].to_i, line[2].to_f
  else
    line[0].to_i
  end
}
#pp options, tc[0..4]
out = []
if options[:format] == "tc1"
  tc.shift
  fps = []
  (tc.length-1).times do |i|
    fps.append(1000/(tc[i+1]-tc[i]).to_f)
  end
  out.append("# timecode format v1","Assume #{sprintf("%.6f", fps.max)}")
  index = 0
  fps.each do |item|
    item = sprintf("%.6f", item)
    if index == 0
      out.append("#{index},#{index},#{item}")
      index+=1
      next
    end
    lastest_item=out[-1].split(",")
    if lastest_item[2] == item
      out[-1].gsub!(/,.+,/, ",#{lastest_item[1]},"=>",#{index},")
    else
      out.append("#{index},#{index},#{item}")
    end
    index+=1
  end
  lastest_item=out[-1].split(",")
  out[-1].gsub!(/,.+,/, ",#{lastest_item[1]},"=>",#{index},")
elsif options[:format] == "tc2"
  # TODO
end
#pp out[-5..-1]
unless options[:output]
  options[:output] = options[:input].split(".")[0..-2].join(".")+"-#{options[:format]}.txt"
end
if File.exist?(options[:output])
  print "File #{options[:output]} already exists. Overwrite ? [y/N] "
  unless gets.strip.downcase == "y"
    puts "Not overwriting - exiting"
    exit
  end
end
File.open(options[:output], mode="w") do |f|
  out.each do |line|
    f.write(line+"\n")
  end
end
puts "Save result as #{options[:output]}"
