#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${DIR}

if [[ $# -ge 1 ]]; then
	MODE=$(echo "$1" | awk '{print tolower($0)}')
else 
     echo "USAGE: ./install_tf_vidgear.sh [server/client]"
     exit 1
fi 
if [[ "${MODE}" == "client" ]] || [[ "${MODE}" == "server" ]]; then
    echo "Using ${MODE} mode"
else
    echo "Please specify either 'server' or 'client'"
    exit 1
fi

echo "Getting helper scripts..."
if [ -d "./debian-scripts/" ]; then
    logWarn "Helper scripts exists already, not installing!"
else 
    git clone https://github.com/otter-in-a-suit/debian-scripts.git
    source debian-scripts/util/logging.sh
    source debian-scripts/util/venv.sh
    source debian-scripts/util/package_installed.sh
    ret=$?

    if [[ $ret -ne 0 ]]; then
        echo "Script installation failed!"
        exit 1
    fi
fi 

logCol "Creating venv "
check_create_venv "${DIR}/.."
if [[ $? -ne 0 ]]; then
    cd "${DIR}/.."
    logErr "venv doesn't exist, please run"
    logErr "python3 -m venv env"
    logErr "source env/bin/activate"
    exit 1
fi

logCol "Installing Python dependencies"
pip3 install -r "../${MODE}/requirements.txt"

logCol "Checking for tensorflow models..."

isInstalled protobuf-compiler
if [[ $? -ne 0 ]]; then
    logErr "protobuf is not installed - please run"
    logErr "sudo apt-get install protobuf-compiler python-pil python-lxml python-tk"
    exit 1
fi

cd ..
if [ -d "./models/" ]; then
    logWarn "Models exists already, not installing!"
else 
    logCol "Installing Tensorflow Models..."
    git clone https://github.com/otter-in-a-suit/models.git
    cd models/research
    protoc object_detection/protos/*.proto --python_out=.
    python3 setup.py build 
    python3 setup.py install 
fi

logCol "Checking for vidgear"
if [ -d "./vidgears/" ]; then
    logWarn "Models exists already, not installing!"
else 
    logCol "Installing vidgear"
    git clone https://github.com/otter-in-a-suit/vidgear.git
    cd vidgear
    pip3 install .
fi

cd "${DIR}"

logCol "Done!"