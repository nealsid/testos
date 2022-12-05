#include <stdarg.h>

char* baseVideoMemory = (char*)0xB8000;
char* currentVideoDisplayPosition = (char*)0xB8000;
const unsigned int COLUMNS = 80;
const unsigned int LINES = 25;
char* baseVideoLimit = (char*)0xB8000 + COLUMNS*LINES*2;

unsigned int getLineNumber() {
  unsigned int lineNumber =
    (currentVideoDisplayPosition - baseVideoMemory) / 2 * COLUMNS;
  return lineNumber;
}

int getColumnNumber() {
  unsigned int columnNumber =
    (currentVideoDisplayPosition - baseVideoMemory) % 160;
  return columnNumber;
}

void incrementLine() {
  currentVideoDisplayPosition += COLUMNS * 2;
}

void incrementColumn() {
  currentVideoDisplayPosition += 2;
}

void clearDisplay() {
  for (unsigned int i = 0; i < (baseVideoLimit - baseVideoMemory); i++) {
    *(baseVideoMemory + i) = 0;
  }
}

/* unsigned int countFormatSpecifiers(const char* formatString) { */
/*   int specifiers = 0; */
/*   const char* ch = formatString; */
/*   while (*ch != '\0') { */
/*     if (*ch == '%' && *(ch + 1) != '\0' && *(ch + 1) != '%') { */
/*       specifiers++; */
/*     } */
/*   } */
/*   return specifiers; */
/* } */

int powersOf10[] = {
  1,
  10,
  100,
  1000,
  10000,
  100000,
  1000000,
  10000000,
  100000000,
  1000000000
};


void convertIntToString(int arg, char* buffer) {
  buffer[0] = '9';
  buffer[1] = '8';
  buffer[2] = '7';
  buffer[3] = '\0';
}


void displayString(const char* formatString, ...) {
  const char* ch = formatString;
  va_list args;
  char buffer[81];
  //  unsigned int count = countFormatSpecifiers(formatString);

  va_start(args, formatString);
  while (*ch != '\0') {
    if (*ch == '\n') {
      incrementLine();
      ch++;
      continue;
    }

    if (*ch == '%') {
      if (*(ch + 1) != '\0' && *(ch + 1) == 'd') {
        int arg = va_arg(args, int);
        convertIntToString(arg, buffer);
        char* bufPtr = buffer;
        while (*bufPtr != '\0') {
          *currentVideoDisplayPosition = *bufPtr;
          currentVideoDisplayPosition++;
          *currentVideoDisplayPosition = 0x7;
          currentVideoDisplayPosition++;
          bufPtr++;
        }
        ch += 2; // skip percent and specifier
        continue;
      }
    }
    *currentVideoDisplayPosition = *ch;
    currentVideoDisplayPosition++;
    *currentVideoDisplayPosition = 0x7;
    currentVideoDisplayPosition++;
    ch++;
  };
}
