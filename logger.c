#include <stdarg.h>
#include <stdbool.h>

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
  currentVideoDisplayPosition -= (currentVideoDisplayPosition - baseVideoMemory) % (COLUMNS * 2);
}

void incrementColumn() {
  currentVideoDisplayPosition += 2;
}

void clearDisplay() {
  for (unsigned int i = 0; i < (baseVideoLimit - baseVideoMemory); i++) {
    *(baseVideoMemory + i) = 0;
  }
}

int powersOf16[] = {
  0x10000000,
  0x1000000,
  0x100000,
  0x10000,
  0x1000,
  0x100,
  0x10,
  0x1,
};

int powersOf10[] = {
  1000000000,
  100000000,
  10000000,
  1000000,
  100000,
  10000,
  1000,
  100,
  10,
  1
};

void convertIntToString(int arg, char* buffer, int* powersOfBaseArray) {
  int powerOfBase;
  bool leadingZero = true;
  if (arg == 0) {
    buffer[0] = '0';
    buffer[1] = '0';
    buffer[2] = '0';
    buffer[3] = '0';
    buffer[4] = '\0';
    return;
  }
  do {
    powerOfBase = *powersOfBaseArray++;

    if (powerOfBase > arg) {
      if (!leadingZero) {
        *buffer++ = '0';
      }
      if (powerOfBase == 1) {
        break;
      }
      continue;
    }
    int multiple = arg / powerOfBase;
    *buffer++ = multiple + (multiple > 9 ? 7 : 0) + '0';
    arg -= multiple * powerOfBase;
    leadingZero = false;
  } while(powerOfBase != 1);
  *buffer = '\0';
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
      if (*(ch + 1) != '\0') {
        char fmtSpecifier = *(ch + 1);
        if (fmtSpecifier == 'd' ||
            fmtSpecifier == 'x') {
          int arg = va_arg(args, int);
          convertIntToString(arg, buffer,
                             fmtSpecifier == 'd' ? powersOf10 : powersOf16);
          char* bufPtr = buffer;
          while (*bufPtr != '\0') {
            *currentVideoDisplayPosition = *bufPtr++;
            currentVideoDisplayPosition++;
            *currentVideoDisplayPosition = 0x7;
            currentVideoDisplayPosition++;
          }
          ch += 2; // skip percent and specifier
          continue;
        }
      }
    }
    *currentVideoDisplayPosition = *ch;
    currentVideoDisplayPosition++;
    *currentVideoDisplayPosition = 0x7;
    currentVideoDisplayPosition++;
    ch++;
  };
  va_end(args);
}
