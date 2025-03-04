#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int shm_unlink(const char *name) {
    size_t namelen;
    char *fname;

    /* Construct the filename.  */
    while (name[0] == '/') ++name;

    if (name[0] == '\0') {
        /* The name "/" is not supported.  */
        errno = EINVAL;
        return -1;
    }

    namelen = strlen(name);
    fname = (char *) alloca(sizeof("@TERMUX_PREFIX@/tmp/") - 1 + namelen + 1);
    memcpy(fname, "@TERMUX_PREFIX@/tmp/", sizeof("@TERMUX_PREFIX@/tmp/") - 1);
    memcpy(fname + sizeof("@TERMUX_PREFIX@/tmp/") - 1, name, namelen + 1);

    return unlink(fname);
}

int shm_open(const char *name, int oflag, mode_t mode) {
    size_t namelen;
    char *fname;
    int fd;

    /* Construct the filename.  */
    while (name[0] == '/') ++name;

    if (name[0] == '\0') {
        /* The name "/" is not supported.  */
        errno = EINVAL;
        return -1;
    }

    namelen = strlen(name);
    fname = (char *) alloca(sizeof("@TERMUX_PREFIX@/tmp/") - 1 + namelen + 1);
    memcpy(fname, "@TERMUX_PREFIX@/tmp/", sizeof("@TERMUX_PREFIX@/tmp/") - 1);
    memcpy(fname + sizeof("@TERMUX_PREFIX@/tmp/") - 1, name, namelen + 1);

    fd = open(fname, oflag, mode);
    if (fd != -1) {
        /* We got a descriptor.  Now set the FD_CLOEXEC bit.  */
        int flags = fcntl(fd, F_GETFD, 0);
        flags |= FD_CLOEXEC;
        flags = fcntl(fd, F_SETFD, flags);

        if (flags == -1) {
            /* Something went wrong.  We cannot return the descriptor.  */
            int save_errno = errno;
            close(fd);
            fd = -1;
            errno = save_errno;
        }
    }

    return fd;
}
