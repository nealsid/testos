#include "logger.h"

void foo();

void kernel_main(void *phys_memory_map) {
  clearDisplay();
  displayString("hello");
  foo();
}

void foo() {
  __asm__("incw 0xF000\n");
 foo:
  goto foo;
}
