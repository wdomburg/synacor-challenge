#!/usr/bin/ruby

require 'optparse'
require './vm'

opts = ARGV.getopts('d')
file = ARGV.shift

vm = VM.new(:debug => opts['d'])
vm.read(file)
vm.run
