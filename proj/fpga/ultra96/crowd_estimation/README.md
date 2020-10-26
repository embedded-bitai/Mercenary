# Where to download image ?  

https://docs.avnet.com/amer/smart_channel/ultra96_v2.3.zip  

# How to burn image to sd card  

```make
#find the disk name that matches your SD card specs e.g /dev/disk2
diskutil list 
#unmount the disk
diskutil unmountDisk /dev/disk2
#use dd tool to write disk image 
sudo dd bs=1m if=/path/to/file.img of=/dev/disk2 conv=sync
```

# Setting Network Interface  

vi /etc/  

```make
#find network interface configuration
ifconfig
#ping Google's DNS server - verify that the board is connected to the internet
ping -c10 8.8.8.8
```

# SW Env Settings  

sudo pip3 install --upgrade git+https://github.com/Xilinx/PYNQ-ComputerVision.git  


