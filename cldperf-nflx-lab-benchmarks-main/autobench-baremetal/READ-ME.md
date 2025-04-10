Steps to run:
1. Download autobench-baremetal
2. Run packages-installed.sh. Might need to give permissions to benchmark files.
3. Start ./start-benchmark <no/perfspec/uProf> : First argument is for profile.
   As name suggest for no profiling, using perfspec and uProf respectively.
4. Select the respective workload to run when prompted. 
5. Results will be stored at /home/bnetflix/efs/html/AUTOBENCH/LAB_RESULTS

** Changes to make while changing uProf binary**
- Download latest uProf. Put it in autobench/binaries folder.
- Rename the folder as uProf
- Copy start_uProf.sh and stop_uProf.sh under this uProf folder

