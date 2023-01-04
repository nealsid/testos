#include "logger.h"

void foo();

struct physical_map_entry {
  long base_lower4;
  long base_upper4;
  long length_lower4;
  long length_upper4;
  int  region_type;
};

void kernel_main(int map_count,
                 struct physical_map_entry *phys_memory_map) {
  clearDisplay();
  displayString("Map of physical memory (%d entries):\n", map_count);
  displayString("Sizeof struct: %d\n", sizeof(struct physical_map_entry));
  for(int i = 0; i < map_count; ++i) {
    displayString("0x%x%x\n", phys_memory_map[i].base_upper4, phys_memory_map[i].base_lower4);
  }
  displayString("%d\n", sizeof(long));
  foo();
}

void foo() {
  __asm__("incw 0xF000\n");
 foo:
  goto foo;
}
