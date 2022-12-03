
void foo();

void displayStr(const char*);

void kernel_main(void *phys_memory_map) {
  *(char*)0xB8000 = '2';
  displayStr("hello");
  foo();
}

void displayStr(const char * str) {
  const char* ch = str;
  char* displayBuffer = (char*)0xB8000;
  while (*ch != '\0') {
    *displayBuffer = *ch;
    displayBuffer++;
    *displayBuffer = 0x07; // grey on black
    displayBuffer++;
    ch++;
  }
}

void foo() {
  __asm__("incw 0xF000\n");
 foo:
  goto foo;
}
