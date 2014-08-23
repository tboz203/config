#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>

/* int main () { */
/*     if (fork() == 0) { */
/*         // child process */
/*         execlp("apt-get", "apt-get", "update", (char *) NULL); */
/*         int e = errno; */
/*         return e; */
/*     } else { */
/*         int status; */
/*         wait(&status); */
/*         if (WIFEXITED(status)) { */
/*             status = WEXITSTATUS(status); */
/*             if (status != 0) { */
/*                 printf("[-] %s\n", strerror(status)); */
/*                 return status; */
/*             } */
/*         } */
/*     } */

/*     if (fork() == 0) { */
/*         execlp("apt-get", "apt-get", "upgrade", (char *) NULL); */
/*         int e = errno; */
/*         return e; */
/*     } else { */
/*         int status; */
/*         wait(&status); */
/*         if (WIFEXITED(status)) { */
/*             status = WEXITSTATUS(status); */
/*             if (status != 0) { */
/*                 printf("[-] %s\n", strerror(status)); */
/*                 return status; */
/*             } */
/*         } */
/*     } */
/* } */

int main () {
    system("echo -n \"whoami \"\n");
    system("whoami\n");
    /* system("apt-get update && apt-get upgrade\n"); */
}
