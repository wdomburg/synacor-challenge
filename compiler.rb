#!/usr/bin/ruby

OP = { "halt" => 0,"set" => 1,"push" => 2,"pop" => 3,"eq" => 4,"gt" => 5,"jmp" => 6,"jt" => 7,"jf" => 8,"add" => 9 ,"mult" => 10,"mod" => 11,"and" => 12,"or" => 13,"not" => 14,"rmem" => 15,"wmem" => 16,"call" => 17,"ret" => 18,"out" => 19,"in" => 20,"noop" => 21 }
code = []
constants = {} 
section = ':main'
sections = {}

ARGF.each do |line|

	tokens = line.partition('//').first.scan(/(\S+)/).flatten

	case tokens[0]
		when /^(:\S+)/
			section = $1
			sections[section] = code.length
			puts section
		when /^(#\S+)/
			sections[section + $1] = code.length
			puts section + $1
		when /^[A-Z]+/
			constant = tokens.shift
			constants[constant] = tokens.map do |token|
				case token
					when /^"(.*)"/
						$1.chars.map { |c| c.ord }
					when /^\+(\d+)/
						puts "Allocating #{$1} words."
						Array.new($1.to_i, 0)
					else
						token
				end
			end.flatten
			puts "#{constant}: #{constants[constant].inspect}"
		when /^$/
			next
		else
			puts "%05i %s" % [code.length, tokens.join(' ')]
			code.concat tokens.map { |token| token =~ /^#/ ? section + token : token }
	end

end

constants.each_pair do |name, value|
	sections[name] = code.length
	code.concat value
end

sections['FREE'] = code.length

code.map! do |token|

	case token
		when /^:\S+/
			sections[token]
		when /^[A-Z]+/
			sections[token]
		when /^@(\d)/
			32768 + $1.to_i
		when /^\d+/
			token.to_i
		else
			OP[token] || token
	end

end

puts

sections.each_pair do |section, offset|
		puts "#{section}: #{offset}"
end

File.open('a.bin', 'w') { |f| f.write(code.pack('S*')) } rescue puts code.inspect
