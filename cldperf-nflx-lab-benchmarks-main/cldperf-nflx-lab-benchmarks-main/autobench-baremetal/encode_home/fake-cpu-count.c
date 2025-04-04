#define _GNU_SOURCE
#include "stdlib.h"
#include <unistd.h>
#include <dlfcn.h>

/**
 compile: gcc -shared -fPIC fake-cpu-count.c -o fake-cpu-count.so -ldl
 export LD_PRELOAD=./fake-cpu-count.so
*/

typedef long int (*orig_sysconf_f_type)(int __name);

long sysconf(int name){
   
  orig_sysconf_f_type orig_sysconf;
  orig_sysconf = (orig_sysconf_f_type)dlsym(RTLD_NEXT,"sysconf");

  if (name == _SC_NPROCESSORS_CONF){
      return 2;
  }

// ffmpeg uses:  int num_cpus = sysconf(_SC_NPROCESSORS_ONLN)
  if (name == _SC_NPROCESSORS_ONLN){
      return 2;
  }

  return orig_sysconf(name);
}

