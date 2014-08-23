#include <unistd.h>

int main () {
    execlp("python", "python", "/usr/bin/scapy", (char *) NULL);
    return 1;
}
