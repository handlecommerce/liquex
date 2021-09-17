#!/usr/bin/env ruby

require 'liquid'
require 'json'

result = Liquid::Template
         .parse(ARGV[0])
         .render(JSON.parse(ARGV[1]))

print result
