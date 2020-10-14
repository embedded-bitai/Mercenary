# First Install Anaconda  

# What we need ?  

Anaconda, Nvidia Driver, CUDA 10.2

# How to build OpenCV 3.4.0 with CUDA 10.2  
sudo apt-get update  
sudo apt install xfce4 xfce4-goodies tightvncserver  
sudo apt-get install build-essential cmake unzip pkg-config  
sudo apt-get install libjpeg-dev libpng-dev libtiff-dev  
sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev v4l-utils libxvidcore-dev libx264-dev libxine2-dev  
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev  
sudo apt-get install libgtk-3-dev  
sudo apt-get install mesa-utils libgl1-mesa-dri libgtkgl2.0-dev libgtkglext1-dev  
sudo apt-get install libatlas-base-dev gfortran libeigen3-dev  
sudo apt-get install python2.7-dev python-numpy  
sudo apt-get install build-essential ccache  
sudo apt-get install cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev tesseract-ocr libtesseract-dev  
sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev  
sudo apt-get install libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev libgtk2.0-dev libgtk-3-dev libpng-dev libjpeg-dev libopenexr-dev libtiff-dev libwebp-dev  

mkdir -p ~/proj/opencv  
cd ~/proj/opencv  

wget https://github.com/opencv/opencv/archive/3.4.9.zip  
wget https://github.com/opencv/opencv_contrib/archive/3.4.9.zip  

unzip opencv-3.4.9.zip  
ln -s opencv-3.4.9 opencv  

unzip opencv_contrib-3.4.9.zip  
ln -s opencv_contrib-3.4.9 opencv_contrib  

cd opencv  
mkdir build  
cd build  
cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D OPENCV_EXTRA_MODULES_PATH=~/proj/opencv/opencv_contrib/modules -D BUILD_NEW_PYTHON_SUPPORT=ON -D WITH_V4L=ON -D WITH_VTK=ON -D INSTALL_C_EXAMPLES=ON -D OPENCV_GENERATE_PKGCONFIG=ON -D PYTHON3_INCLUDE_DIR=/home/bitai/anaconda3/include/python3.7m/ -D PYTHON3_NUMPY_INCLUDE_DIRS=/home/bitai/anaconda3/lib/python3.7/site-packages/numpy/core/include/ -D PYTHON3_PACKAGES_PATH=/home/bitai/anaconda3/lib/python3.7/site-packages -D PYTHON3_LIBRARY=/home/bitai/anaconda3/lib/libpython3.7m.so -D INSTALL_PYTHON_EXAMPLES=ON -D BUILD_EXAMPLES=ON -D ENABLE_FAST_MATH=1 -D CUDA_FAST_MATH=1 -D WITH_CUBLAS=1 -D WITH_OPENGL=ON -D WITH_CUDA=ON -D CUDA_ARCH_BIN="6.1" -D CUDA_ARCH_PTX="6.1" -DBUILD_opencv_cudacodec=OFF ..  

make -j$(nproc)  

sudo make install  
sudo /bin/bash -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'  
sudo ldconfig  

cp -aur ~/proj/opencv/opencv/samples/data ./
cd ~/proj/opencv/opencv/build/bin  
./example_gpu_opticalflow  
