
void foo();

void displayStr(char* const);

void kernel_main(void *phys_memory_map) {
  displayStr("Hello");
  foo();
}

void displayStr(char * const str) {
  char* ch = str;
  char* displayBuffer = (char*)0xB8000;
  while (*ch != '\0') {
    *displayBuffer = *ch;
    displayBuffer++;
    *displayBuffer = 0x07; // grey on black
    displayBuffer++;
  }
}

void foo() {
  __asm__("incw 0xF000\n");
 foo:
  goto foo;
}
