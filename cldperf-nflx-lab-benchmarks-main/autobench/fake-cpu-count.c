#define _GNU_SOURCE
#include <stdlib.h>
#include <unistd.h>
#include <dlfcn.h>

/**
 * Usage:
 *   gcc -shared -fPIC fake-cpu-count.c -o fake-cpu-count.so -ldl
 *   export CPUS=4
 *   export LD_PRELOAD=/path/to/fake-cpu-count.so
 */

typedef long int (*orig_sysconf_f_type)(int);

long sysconf(int name)
{
    static orig_sysconf_f_type real_sysconf = NULL;
    if (!real_sysconf) {
        real_sysconf = (orig_sysconf_f_type)dlsym(RTLD_NEXT, "sysconf");
    }

    // Default to 1 if CPUS isn’t set or is invalid
    long fake_cpus = 1;

    char *env_cpus = getenv("CPUS");
    if (env_cpus) {
        long tmp = atol(env_cpus);
        if (tmp > 0) {
            fake_cpus = tmp;
        }
    }

    if (name == _SC_NPROCESSORS_CONF || name == _SC_NPROCESSORS_ONLN) {
        return fake_cpus;
    }
    return real_sysconf(name);
}

