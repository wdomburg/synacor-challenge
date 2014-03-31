SYMROOT +52					
INPUT   +80
ROUTINES "HI" 0 :hi "BYE" 0 :bye "EXIT" 0 :exit 0

EINVAL "Invalid" 32 "command." 10 0

set  @7 FREE				// set free memory ptr

// stores pointers to routines into symbol table
set  @1 ROUTINES
#0
set  @0 SYMROOT
call :lookup				// fetch symbol ptr
add  @1 @1 1				// increment table location
rmem @2 @1					// read location
wmem @0 @2					// write location into symbol table
add  @1 @1 1				// advance to the next
rmem @2 @1					// read location
jt   @2 #0					// repeat until exhausted

#1							// command input
out 62
out 32
set  @0 INPUT
set  @1 10 
call :gets					// read command into buffer
set  @0 SYMROOT
set  @1 INPUT
call :lookup				// get ptr
rmem @6 @0					// resolve ptr
jt   @6 #3					// execute if command is found
set  @0 EINVAL
call :puts					// bad input
jmp  #1
#3 
call @6
jmp  #1

halt

:hi
		out  72
		out  73
		out  10
		ret

:bye
		out  66
		out  89
		out  69
		out  10
		ret

:exit
		halt

:malloc
	#1
		add  @1 @0 @7		// calculate new next position
		set  @0 @7			// store beginning pointer to return
		set  @7 @1			// store new next position
		ret

:lookup
	#1
		rmem @2 @1			// read character into register
	#2
		add  @1 @1 1		// increment the symbol ptr
		rmem @3 @1			// read next character into register
		jf   @3 #4			// found target node; jump to final
		add  @2 @2 32729 	// calculate offset (subt 39 from char)
		add  @0 @0 @2		// increment ptr by offset
		rmem @2 @0			// resolve ptr to next table
		jt   @2 #3			// skip malloc if table exists
		wmem @0 @7			// store addr of new table
		add  @7 @7 52		// allocate space for new table
	#3
		rmem @0 @0			// resolve the table ptr
		set  @2 @3			// copy char instead of reading it again
		jmp  #2				// loop
	#4
		add  @2 @2 32703	// calculate offset (subt 65 from char)
		add  @0 @0 @2		// increment ptr by offset
		ret
  
:gets						// todo: restore @0 to beginning of string?
	#1
		in   @1				// read character into register
		eq   @2 @1 10		// check for newline
		jt   @2 #2			// jump to end 
		wmem @0 @1			// write character to memory
		add  @0 @0 1		// increment the ptr
		jmp  #1				// keep going
	#2
		wmem @0 0			// terminate string with null
		ret

:puts
	#1
		rmem @1 @0			// read character into register
		jf   @1 #2			// jump if we hit terminator
		out  @1				// print the character
		add  @0 @0 1		// increment the ptr
		jmp  #1				// loop
	#2
		ret					// return

// @0 buffer @1 scan (@2 char @3 eq) 
:scan
	#1
		rmem @2 @0			// read character into register
		jf   @2 #2			// jump null return if we hit end of string
		eq   @3 @2 @1		// check if we hit scan char
		jt   @3 #3			// jump to end if we got a hit
		add  @0 @0 1		// increment the ptr
		jmp  #1				// loop
	#2
		set  @0 0
	#3
		ret					//return
