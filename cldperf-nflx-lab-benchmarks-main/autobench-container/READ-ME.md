Steps to run:
1. Firstly, we need to create a docker image. There is a Dockerfile in the autobench folder.
   Make change to Dockerfile ENTRYPOINT ["/home/bnetflix/run-benchmarks-<>"] depending upon your profiling preference.
   By default, it is set to perfspec.
   For no profiling, change it to ENTRYPOINT ["/home/bnetflix/run-benchmarks-noprofile"]
   For profiling with uProf, change it to ENTRYPOINT ["/home/bnetflix/run-benchmarks-uProf"]

2. Once saving the change to Dockerfile. Build the docker image :
    docker build -t benchmark-container .
    Note: Do not change the image name. It need to be benchmark-container.

3. ./launch-container-concurrent <instance-size>
    Options: xlarge, 2xlarge, 4xlarge, 8xlarge, 12xlarge, 16xlarge, 24xlarge, 32xlarge, metal-48xl

By default results will get mapped to host at /home/bnetflix/efs. You can change that in launch-container-concurrent.sh in docker run command.