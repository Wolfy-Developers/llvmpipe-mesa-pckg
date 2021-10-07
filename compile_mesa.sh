#!/bin/bash

# Declare constants
OS_TYPE=$(uname -s)
OS_VER=$(uname -r)

TMP_FOLDER="${HOME}/mesa_tmp_build"

# Package dependencies for the host
APT_HOST_DEPENDENCIES="build-essential uuid-dev libssl-dev libreadline-dev zlib1g-dev libsqlite3-dev  liblzma-dev libncurses5-dev libbz2-dev libgdbm-dev make wget libgdbm-dev libnss3-dev libffi-dev bzip2 libc6-dev libncursesw5-dev libdb5.3-dev libexpat1-dev git cmake libgtk-3-dev curl freeglut3 freeglut3-dev debhelper dh-make"
PIP_HOST_DEPENDENCIES="flex bison mako meson ninja make"

function show_welcome_message()
{
    echo "====== Mesa 3D OpenGL LLVMpipe Software Rendering DEB Packager  ======"
    echo "================== Script writed by Zhymabek Roman  ==================="
}


function show_system_info()
{
    echo ">>> OS: $(lsb_release -si) $(lsb_release -sr), $(lsb_release -sc)"
    echo ">>> OS kernel: ${OS_TYPE}, ${OS_VER}"
    echo ">>> Processor architecture type: ${HOSTTYPE}"
    echo ">>> Device hostname: ${HOSTNAME}"
}


function clone_mesa_repo()
{
    local mesa_version=$1

    echo "Cloning Mesa 3D repository, version: ${mesa_version}"
    mkdir ${TMP_FOLDER}/mesa_src/
    git clone --depth=1 --branch=mesa-${mesa_version} https://gitlab.freedesktop.org/mesa/mesa.git ${TMP_FOLDER}/mesa_src/${mesa_version}
}


function build_python_src()
{
    mkdir ${TMP_FOLDER}/python3_src/
    cd ${TMP_FOLDER}/python3_src/
    wget https://www.python.org/ftp/python/3.7.10/Python-3.7.10.tar.xz
    tar -xf Python-3.7.10.tar.xz
    cd Python-3.7.10
    ./configure --prefix=/opt/python-3.7.10
    make -j 8
    sudo make install
    export PATH=/opt/python-3.7.10/bin:$PATH
}

function install_pip3_and_depends()
{
    # export PATH=/opt/python-3.7.10/bin:$PATH
    curl https://bootstrap.pypa.io/get-pip.py -o ${TMP_FOLDER}/get-pip.py
    python3 ${TMP_FOLDER}/get-pip.py

    python3 -m pip install ${PIP_HOST_DEPENDENCIES}
}

function build_mesa_src()
{
    local mesa_version=$1

    sudo sed -i 's/# deb-src/deb-src/' /etc/apt/sources.list
    sudo apt update
    sudo apt-get build-dep mesa -y -qq

    cd ${TMP_FOLDER}/mesa_src/${mesa_version}
    
    BUILD_TYPE=release
    BUILD_OPTIMIZATION=3

    meson \
        --buildtype=${BUILD_TYPE} \
        --sysconfdir=/etc \
         --prefix=/usr/local \
        -D b_ndebug=true \
        -D egl=false \
        -D gallium-nine=false \
        -D gallium-xvmc=false \
        -D gbm=false \
        -D gles1=false \
        -D gles2=false \
        -D opengl=true \
        -D dri-drivers= \
        -D dri3=false  \
        -D egl=false \
        -D gallium-drivers= \
        -D gbm=false \
        -D shader-cache=true \
        -D llvm=true \
        -D lmsensors=false \
        -D optimization=${BUILD_OPTIMIZATION} \
        -D platforms=x11 \
        -D shared-glapi=true \
        -D shared-llvm=true \
        -D vulkan-drivers= \
        -D osmesa=classic \
        build/;
    # ninja -C build/
    # sudo ninja -C build/ install
}


function space()
{
    local message=$1

    echo -e "\n${message}\n"
}


function main()
{
    # TODO: first install sudo apt-get install software-properties-common wget
    # and enable universal repositories: sudo add-apt-repository universe
    mkdir ${TMP_FOLDER}
    show_welcome_message
    space
    show_system_info
    space "Stage 0: install depends"
    sudo apt install -qq -y ${APT_HOST_DEPENDENCIES}
#     space "Stage 1: build and install Python 3.7.10"
#     build_python_src
    space "Stage 2: install pip3 and depends"
    install_pip3_and_depends 
    space "Stage 3: cloning Mesa 3D Repository"
    clone_mesa_repo "20.0.0"
    space "Stage 4: build Mesa 3D LLVMpipe"
    build_mesa_src "20.0.0"
}

main
