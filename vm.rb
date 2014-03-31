class VM

	require 'pp'

	attr_accessor :position, :memory, :stack, :debug

	OP = []
	OP_ARG = []

	MAXINT    = 32767
	MEMORY    = 0..32767
	REGISTER  = 32768..32775

	def initialize(opts = {})
		@stack = Array.new
		@debug = opts.has_key?(:debug) ? opts[:debug] : false
	end

	def read(file)
		memory = File.read(file).unpack('S*')

		self.load(memory)
	end

	def load(memory = [])
		@stack.clear
		@memory = memory
		@memory.fill(0,memory.length,32775)
		@position = 0
		self
	end

	def[](pos)
		self.memory[pos]
	end

	def step
		return nil if @position.nil?
		raise "Position unset" if @position.nil?
		raise "Position invalid" unless opcode = @memory[@position]
		raise "Unimplemented opcode: #{opcode}" unless op = OP[opcode]

		if debug 
			STDERR.puts "%-5i %4s %s" % [ @position, op, @memory.slice(@position+1,OP_ARG[opcode]).pretty_inspect ] if debug
		end
		nxt = self.send(op)
		if debug 
			STDERR.puts "  REGS : " + REGISTER.map { |n| "%i: %5i" % [n, @memory[n]] }.join(' ')
			STDERR.puts "  STACK: " + @stack.join(' ')
		end
		nxt
	end

	def run
		begin
			while self.step; end
		rescue => e
			puts "ERROR: #{e.message}"
			puts e.backtrace
		end
	end

	def _arg(offset)
		_get(@position + offset)
	end

	def _rarg(offset)
		@memory[@position + offset]
	end

	def _get(addr)
		case addr
			when REGISTER
				@memory[addr]
			when MEMORY
				value = @memory[addr]
				case value
					when REGISTER
						_get(value)
					when MEMORY
						value
					else
						raise "Invalid!"
				end
			else
				raise "Invalid address: #{addr}"
		end
	end

	def _set(addr, value)
		@memory[addr] = value
	end

	def _jmp(position)
		@position = position
	end

	def _nxt(offset = 0)
		@position + offset + 1
	end

	def _push(val)
		@stack << val
	end

	def _pop
		@stack.pop or raise "Tried to pop empty stack."
	end

	class << self

		def op(code, args, name, &blk)
			OP[code] = name
			OP_ARG[code] = args
			define_method(name, &blk)
		end

	end

	# stop execution and terminate the program
	#
	op(0, 0, :halt)  { nil }

	# set register <a> to the value of <b>
	op(1, 2, :set)   { _set(_rarg(1), _arg(2)); _jmp(_nxt(2))}

	# push <a> onto the stack
	op(2, 1, :push)  { _push(_arg(1)); _jmp(_nxt(1)) }

	# remove the top element from the stack and write it into <a>; empty stack = error
	op(3, 1, :pop)   { _set(_rarg(1), _pop); _jmp(_nxt(1)) }

	# set <a> to 1 if <b> is equal to <c>; set it to 0 otherwise
	op(4, 3, :eq)    { _set(_rarg(1), (_arg(2) == _arg(3)) ? 1 : 0); _jmp(_nxt(3)) }

	# set <a> to 1 if <b> is greater than <c>; set it to 0 otherwise
	op(5, 3, :gt)    { _set(_rarg(1), (_arg(2) > _arg(3)) ? 1 : 0); _jmp(_nxt(3)) }

	# jump to <a>
	op(6, 1, :jmp)   { _jmp(_arg(1)) }

	# if <a> is nonzero, jump to <b>
	op(7, 2, :jt)    { _jmp(_arg(1) != 0 ? _arg(2) : _nxt(2)) }

	# if <a> is zero, jump to <b>
	op(8, 2, :jf)    { _jmp(_arg(1) == 0 ? _arg(2) : _nxt(2)) }

	# assign into <a> the sum of <b> and <c> (modulo 32768)
	op(9, 3, :add)   { _set(_rarg(1), (_arg(2) + _arg(3)) % 32768); _jmp(_nxt(3)) }

	# store into <a> the product of <b> and <c> (modulo 32768)
	op(10, 3, :mult) { _set(_rarg(1), (_arg(2) * _arg(3)) % 32768); _jmp(_nxt(3)) }

	# store into <a> the remainder of <b> divided by <c>
	op(11, 3, :mod)  { _set(_rarg(1), _arg(2) % _arg(3)); _jmp(_nxt(3)) }

	# stores into <a> the bitwise and of <b> and <c>
	op(12, 3, :and)  { _set(_rarg(1), (_arg(2) & _arg(3))); _jmp(_nxt(3)) }

	# stores into <a> the bitwise or of <b> and <c>
	op(13, 3, :or)   { _set(_rarg(1), (_arg(2) | _arg(3))); _jmp(_nxt(3)) }

	# stores 15-bit bitwise inverse of <b> in <a>
	op(14, 2, :not)  { _set(_rarg(1), (MAXINT ^ _arg(2))); _jmp(_nxt(2)) }

	# read memory at address <b> and write it to <a>
	op(15, 2, :rmem) { _set(_rarg(1), _get(_arg(2))); _jmp(_nxt(2)) }

	# write the value from <b> into memory at address <a>
	op(16, 2, :wmem) { _set(_arg(1), _arg(2)); _jmp(_nxt(2)) }

	# write the address of the next instruction to the stack and jump to <a>
	op(17, 1, :call) { _push(_nxt(1)); _jmp(_arg(1)) }

	# remove the top element from the stack and jump to it; empty stack = halt
	op(18, 0, :ret)  { _jmp(_pop) }

	# write the character represented by ascii code <a> to the terminal
	op(19, 1, :out)  { putc _arg(1); _jmp(_nxt(1)) }

	# read a character from the terminal and write its ascii code to <a>
	op(20, 1, :in)   { _set(_rarg(1), STDIN.getc.ord); _jmp(_nxt(1))  }

	# no operation
	op(21, 0, :noop) { _jmp(_nxt) }

end
