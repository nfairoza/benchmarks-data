Steps to follow to run benchmark in container(s) on baremetal.

1. Go to autobench folder. Build docker image:
	sudo docker build -t benchmark-container . 

2. To start benchmarking, use the provided script: 
	./launch_containers-concurrent.sh xlarge

Note: Container launch script support container shapes that mimic popular AWS instance types in terms of vcpu and memory configured. Supported shapes are:: 
xlarge, 2xlarge, 4xlarge, 8xlarge, 12xlarge, 16xlarge, 24xlarge, 32xlarge, metal-48xl


Changes needed:
- In 'Launch_containers-concurrent.sh' : Change host mount point in 'docker run -v <>: /home/bnetflix/efs' command
- Please use provided Dockerfile as it provides permissions which are not present in orig_Dockerfile
