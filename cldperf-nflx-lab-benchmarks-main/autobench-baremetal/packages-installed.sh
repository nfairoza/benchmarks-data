### PACKAGES INSTALLED ON THE MACHINE ####
export DEBIAN_FRONTEND=noninteractive
. /etc/os-release
sudo apt update -y
sudo apt install openjdk-17-jre-headless -y 
sudo apt install openjdk-17-jdk-headless -y 
sudo apt install linux-headers-$(uname -r) -y
sudo apt install p7zip-full -y 
sudo apt install sysbench -y 
sudo apt install lmbench -y
sudo apt install docker.io -y 
sudo apt install docker-compose -y
sudo apt install docker-compose-plugin -y
sudo apt install cgroup-tools -y 
sudo usermod -a -G docker bnetflix
sudo chown bnetflix:bnetflix /home/bnetflix/.docker -R
sudo chmod g+rwx /home/bnetflix/.docker -R
sudo systemctl restart docker
sudo chmod 666 /var/run/docker.sock
sudo systemctl restart containerd
sudo systemctl restart docker
sudo apt install python3-pip -y 
sudo apt install python3 -y
sudo apt install python3.12-venv -y
sudo apt install g++ -y
if lspci | grep -i nvidia; then
    echo "NVIDIA GPU detected. Proceeding with installation..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    sudo apt update
    sudo apt -y install cuda-toolkit
    sudo apt install -y nvidia-driver-565
    sudo apt -y install nvidia-cuda-toolkit
    sudo rmmod nouveau
    sudo apt-get install -y nvidia-fabricmanager-560
    sudo systemctl start nvidia-fabricmanager.service
    sudo apt -y install nvidia-container-toolkit
    echo "Installation completed!"
fi
chmod +x benchmarks_environment.sh run-benchmarks-noprofile run-benchmarks-uProf run-benchmarks-perfspec start-benchmark sys-report.sh
chmod +x ./binaries/perfspect/start_perfspect.sh
chmod +x ./binaries/perfspect/stop_perfspect.sh
chmod +x ./binaries/uProf/start_uProf.sh 
chmod +x ./binaries/uProf/stop_uProf.sh
chmod +x ./binaries/perfspect/perfspect
chmod +x ./binaries/uProf/bin/AMDuProfPcm
chmod +x ./binaries/mlc/Linux/mlc

