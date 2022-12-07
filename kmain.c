#include "logger.h"

void foo();

void kernel_main(void *phys_memory_map) {
  clearDisplay();
  displayString("%d", 12345);
  displayString("\n0x%x", 12345);
  foo();
}

void foo() {
  __asm__("incw 0xF000\n");
 foo:
  goto foo;
}
