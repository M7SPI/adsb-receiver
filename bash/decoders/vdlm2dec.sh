#!/bin/bash

## PRE INSTALLATION OPERATIONS

source $RECEIVER_BASH_DIRECTORY/variables.sh
source $RECEIVER_BASH_DIRECTORY/functions.sh

clear
log_project_title
log_title_heading "Setting up the VDLM2DEC decoder"
log_title_message "------------------------------------------------------------------------------"
if ! whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" \
              --title "VDLM2DEC decoder Setup" \
              --yesno "VDLM2DEC is a vdl mode 2 decoder with built-in rtl_sdr or airspy front end.\n\nWould you like to begin the setup process now?" \
              11 78; then
    echo ""
    log_alert_heading "INSTALLATION HALTED"
    log_alert_message "Setup has been halted at the request of the user"
    echo ""
    log_title_message "------------------------------------------------------------------------------"
    log_title_heading "VDLM2DEC decoder setup halted"
    echo ""
    exit 1
fi


## GATHER REQUIRED INFORMATION FROM THE USER

log_heading "Determine the device type to build VDLM2DEC for"

log_message "Asking which type of device will be used by VDLM2DEC"
device=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" \
                  --title "Device Type" \
                  --menu "Please choose the RTL-SDR device type which is to be used by VDLM2DEC." \
                  11 78 3 \
                  "RTL-SDR" "" \
                  "AirSpy" "" \
                  3>&1 1>&2 2>&3)
exit_status=$?
if [[ $exit_status != 0 ]]; then
    echo ""
    log_alert_heading "INSTALLATION HALTED"
    log_alert_message "Setup has been halted at the request of the user"
    echo ""
    log_title_message "------------------------------------------------------------------------------"
    log_title_heading "VDLM2DEC decoder setup halted"
    echo ""
    exit 1
fi

ask_for_device_assignments "vdlm2dec"
if [[ $? -ne 0 ]] ; then
    log_alert_heading "INSTALLATION HALTED"
    log_alert_message "Setup has been halted due to lack of required information"
    echo ""
    log_title_message "------------------------------------------------------------------------------"
    log_title_heading "ACARSDEC decoder setup halted"
    exit 1
fi


## CHECK FOR PREREQUISITE PACKAGES

check_package cmake
check_package libjansson-dev
check_package libsqlite3-dev
check_package libxml2-dev
check_package zlib1g-dev


case $RECEIVER_OS_DISTRIBUTION in
    ubuntu)
        distro_php_version=""
        ;;
    debian)
        if [[ "${RECEIVER_OS_CODE_NAME}" == "bookworm" ]]; then distro_php_version="8.2"; fi
        if [[ "${RECEIVER_OS_CODE_NAME}" == "bullseye" ]]; then distro_php_version="7.4"; fi
        ;;
esac
check_package sqlite3
check_package php${distro_php_version}-sqlite3


## BLACKLIST UNWANTED RTL-SDR MODULES

log_heading "Blacklist unwanted RTL-SDR kernel modules"

blacklist_modules


## CLONE OR PULL THE LIBACARS GIT REPOSITORY

log_heading "Preparing the libacars Git repository"

if [[ -d $RECEIVER_BUILD_DIRECTORY/libacars && -d $RECEIVER_BUILD_DIRECTORY/libacars/.git ]]; then
    log_message "Entering the libacars git repository directory"
    cd $RECEIVER_BUILD_DIRECTORY/libacars
    log_message "Updating the local libacars git repository"
    echo ""
    git pull
else
    log_message "Entering the libacars build directory"
    cd $RECEIVER_BUILD_DIRECTORY
    log_message "Cloning the libacars git repository locally"
    echo ""
    git clone https://github.com/szpajder/libacars.git
fi


## BUILD AND INSTALL THE LIBACARS LIBRARY

log_heading "Building the libacars library"

if [[ ! -d $RECEIVER_BUILD_DIRECTORY/libacars/build ]]; then
    log_message "Creating the libacars build directory"
    echo ""
        mkdir -vp $RECEIVER_BUILD_DIRECTORY/libacars/build
    echo ""
fi
if [[ -n "$(ls -A $RECEIVER_BUILD_DIRECTORY/libacars/build 2>/dev/null)" ]]; then
    log_message "Deleting all files currently residing in the libacars build directory"
    rm -rf $RECEIVER_BUILD_DIRECTORY/libacars/build/*
fi
log_message "Entering the libacars build directory"
cd $RECEIVER_BUILD_DIRECTORY/libacars/build
log_message "Executing cmake"
echo ""
cmake ../
echo ""
log_message "Executing make"
echo ""
make
echo ""
log_message "Executing make install"
echo ""
sudo make install
echo ""
log_message "Running ldconfig"
sudo ldconfig


## CLONE OR PULL THE VDLM2DEC GIT REPOSITORY

log_heading "Preparing the VDLM2DEC Git repository"

if [[ -d $RECEIVER_BUILD_DIRECTORY/vdlm2dec && -d $RECEIVER_BUILD_DIRECTORY/vdlm2dec/.git ]]; then
    log_message "Entering the VDLM2DEC git repository directory"
    cd $RECEIVER_BUILD_DIRECTORY/vdlm2dec
    log_message "Updating the local VDLM2DEC git repository"
    echo ""
    git pull
else
    log_message "Entering the build directory"
    cd $RECEIVER_BUILD_DIRECTORY
    log_message "Cloning the VDLM2DEC git repository locally"
    echo ""
    git clone https://github.com/TLeconte/vdlm2dec.git
fi


## BUILD AND INSTALL THE VDLM2DEC BINARY

log_heading "Building the VDLM2DEC binary"

if [[ ! -d $RECEIVER_BUILD_DIRECTORY/vdlm2dec/build ]]; then
    log_message "Creating the VDLM2DEC build directory"
    echo ""
        mkdir -vp $RECEIVER_BUILD_DIRECTORY/vdlm2dec/build
    echo ""
fi
if [[ -n "$(ls -A $RECEIVER_BUILD_DIRECTORY/vdlm2dec/build 2>/dev/null)" ]]; then
    log_message "Deleting all files currently residing in the VDLM2DEC build directory"
    rm -rf $RECEIVER_BUILD_DIRECTORY/vdlm2dec/build/*
fi
log_message "Entering the VDLM2DEC build directory"
cd $RECEIVER_BUILD_DIRECTORY/vdlm2dec/build

log_message "Executing cmake"
echo ""
case "${device}" in
    "RTL-SDR")
        cmake .. -Drtl=ON
        ;;
    "AirSpy")
        cmake .. -Dairspy=ON
        ;;
esac
echo ""

log_message "Executing make"
echo ""
make
echo ""
log_message "Executing make install"
echo ""
sudo make install


## CLONE OR PULL THE ACARSSERV GIT REPOSITORY

log_heading "Preparing the acarsserv Git repository"

if [[ -d $RECEIVER_BUILD_DIRECTORY/acarsserv && -d $RECEIVER_BUILD_DIRECTORY/acarsserv/.git ]]; then
    log_message "Entering the acarsserv git repository directory"
    cd $RECEIVER_BUILD_DIRECTORY/acarsserv
    log_message "Updating the local acarsserv git repository"
    echo ""
    git pull
else
    log_message "Entering the build directory"
    cd $RECEIVER_BUILD_DIRECTORY
    log_message "Cloning the acarsserv git repository locally"
    echo ""
    git clone https://github.com/TLeconte/acarsserv.git
fi


## BUILD AND INSTALL THE ACARSSERV BINARY

log_heading "Building the ACARSSERV binary"

log_message "Entering the acarsserv build directory"
cd $RECEIVER_BUILD_DIRECTORY/acarsserv
log_message "Executing make"
echo ""
make -f Makefile
echo ""


## RUN VDLM2DEC AND ACARSSERV

log_message "Creating the VDLM2DEC systemd service script"
sudo tee /etc/systemd/system/vdlm2dec.service > /dev/null <<EOF
[Unit]
Description=ARCARSDEC multi-channel acars decoder.
After=network.target

[Service]
ExecStart=/usr/local/bin/vdlm2dec -j 127.0.0.1:5555 -G -g280 -r 0 136.725 136.775 136.875 136.975
WorkingDirectory=/usr/local/bin
StandardOutput=null
TimeoutSec=30
Restart=on-failure
RestartSec=30
StartLimitInterval=350
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
EOF

log_message "Creating the ACARSSERV systemd service script"
sudo tee /etc/systemd/system/acarsserv.service > /dev/null <<EOF
[Unit]
Description=ARCARSSERV saves acars data to SQLite.
After=network.target

[Service]
ExecStart=${RECEIVER_BUILD_DIRECTORY}/acarsserv/acarsserv -j 127.0.0.1:5555
WorkingDirectory=${RECEIVER_BUILD_DIRECTORY}/acarsserv
StandardOutput=null
TimeoutSec=30
Restart=on-failure
RestartSec=30
StartLimitInterval=350
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
EOF

log_message "Enabling then starting the VDLM2DEC service"
sudo systemctl enable --now vdlm2dec.service
log_message "Enabling then starting the acarsserv service"
sudo systemctl enable --now acarsserv.service


## CONFIGURATION

assign_devices_to_decoders


## POST INSTALLATION OPERATIONS

whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" \
         --title "VDLM2DEC Decoder Setup Complete" \
         --msgbox "The setup process currently sets basic parameters needed to feed acarsserv. You can fine tune your installation by modifying the startup command found in the file /etc/systemd/system/vdlm2dec.service. Usage information for VDLM2DEC can be found in the projects README at https://github.com/TLeconte/vdlm2dec." \
         12 78


## SETUP COMPLETE

log_message "Returning to ${RECEIVER_PROJECT_TITLE} root directory"
cd $RECEIVER_ROOT_DIRECTORY

echo ""
log_title_message "------------------------------------------------------------------------------"
log_title_heading "VDLM2DEC decoder setup is complete"
echo ""
read -p "Press enter to continue..." discard

exit 0
