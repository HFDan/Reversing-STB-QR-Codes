#!/usr/bin/bash

########## CONFIG
CHECK_OS=y
INSTALL_DEPS=y

function check_os() {
    if [[ "${OSTYPE}" != "linux-gnu" ]]; then
        echo "Only linux is supported"
        exit
    fi
}

PKGMAN=""
PKGMAN_ARGS=""
PKGMAN_CHECK_CMD=""
function get_packagemanager() {
    source "/etc/os-release"

    if [[ "${ID}" == "arch" ]]; then
        PKGMAN=pacman
        PKGMAN_ARGS="--noconfirm -S"
        PKGMAN_CHECK_CMD="pacman -Qss"
        DEPS=(zbar git less)
    elif [[ "${ID}" == "debian" || "${ID_LIKE}" == "debian" ]]; then
        PKGMAN=apt
        PKGMAN_ARGS="install"
        PKGMAN_CHECK_CMD="dpkg -s"
        DEPS=(zbar-tools git)
    else
        DEPS=(zbar)
        echo "Your distro is not supported for automatic dependency installation. Please install: ${DEPS[*]}"
        echo "After installing, modify the script's CONFIG section to not install deps and/or check os"
        exit
    fi
}

function install_deps() {
    if [[ ${EUID} -ne 0 ]]; then
        local install_cmd="sudo "
    fi
    local install_cmd="${install_cmd}${PKGMAN} ${PKGMAN_ARGS}"
    
    echo "Installing dependencies..."
    for dep in "${DEPS[@]}"
    do
        if [[ $(${PKGMAN_CHECK_CMD} ${dep} 2>/dev/null) == "" ]]; then
            ${install_cmd} ${dep}
        else
            echo "${dep} is already installed"
        fi
    done
}

function main() {
    
    if [[ "${CHECK_OS}" == "y" ]]; then
        check_os
    fi
    
    get_packagemanager
    install_deps

    local script_path=$(dirname -- "${BASH_SOURCE[0]}")
    local dir=${script_path}/qr/${filename%.*}

    if [[ $1 == "unpack" ]]; then


        local filename=$(basename $2)
        mkdir -p ${dir}
        /usr/bin/zbarimg $2 --oneshot --raw -q > ${dir}/${filename%.*}.bin &&
        /usr/bin/hexdump -C ${dir}/${filename%.*}.bin > ${dir}/${filename%.*}.hex

    elif [[ $1 == "diff" ]]; then

        local less="/usr/bin/less"
        if [[ -f "/usr/bin/bat" ]]; then
            less="/usr/bin/bat"
        fi
        git difftool --no-index --word-diff=color --word-diff-regex=. \
        ${script_path}/qr/${2}/${2}.hex ${script_path}/qr/${3}/${3}.hex 

    fi
}
main $@