set architecture i386:x86-64
target remote localhost:1234
alias efl = inf reg eflags
define qd
  detach
  quit
end

define dump-interrupt-counters
  x /256wx 0x1A000
end

display /i $pc

break *0x7c00
cont
