
void foo();

void kernel_main() {
  __asm__("incw 0x1000\n"
          "cpuid\n");
  foo();
}

void foo() {
  __asm__("incb 0x1000\n");
}
