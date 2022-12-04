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

void displayString(const char* formatString) {
  const char* ch = formatString;
  while (*ch != '\0') {
    if (*ch == '\n') {
      incrementLine();
      ch++;
      continue;
    }
    *currentVideoDisplayPosition = *ch;
    currentVideoDisplayPosition++;
    *currentVideoDisplayPosition = 0x7;
    currentVideoDisplayPosition++;
    ch++;
  };
}
