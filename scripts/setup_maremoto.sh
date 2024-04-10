#!/usr/bin/env bash

# NOTE: run as root
# NOTE: use on 20_maremoto

# ---

update_system(){
    if [ ! -e "/etc/apt/apt.conf.d/99show-versions" ]; then
        echo 'APT::Get::Show-Versions "true";' > /etc/apt/apt.conf.d/99show-versions
    fi

    apt update && apt upgrade -y && apt autoremove -y && apt autoclean
}


setup_misc(){
    apt install -y \
        netdiscover
}


# ---

install_elk_dependencies(){

    dependencies=(
        'nginx'
        'java'
    )

    for dep in ${dependencies[@]}; do

        if ! dpkg -l | grep -q "$dep"; then
            apt-get install "$dep"
        fi

    done

}

install_elk_packages(){

    packages=(
        'foo'
        'bar'
    )

    for pkg in ${packages[@]}; do

        if ! dpkg -l | grep -q "$pkg"; then
            wget "$pkg".deb
            dpkg -i "$pkg".deb
        fi

    done
}

setup_elasticstack(){
    # https://www.youtube.com/watch?v=cC4GGJ0JsSE

    install_elk_dependencies
    install_elk_packages

}

# ---

setup_suricata(){
    false
}


# ---x---


# if true; then
#     update_system
#     setup_misc

#     setup_elasticstack
#     setup_suricata
# fi
