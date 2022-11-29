
void foo();

void kernel_main() {
  __asm__("incw 0xF000\n");
  foo();
}

void foo() {
  __asm__("incw 0xF000\n");
 foo:
  goto foo;
}
