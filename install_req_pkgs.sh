#!/bin/bash


# install in oracle linux 9, packages required by Forms Builder installation

set -eu 
SECONDS=0
printf "\tcreate "user:group" oracle:oracle\n"
 groupadd oracle
 useradd -g oracle oracle
 passwd -d oracle

printf "install update source and xorg packages\n"
 dnf -y install oracle-epel-release-el9.x86_64
 dnf -y install xorg-x11-xauth xorg-x11-utils make

printf "dnf install required packages...\n"
 dnf -y install binutils-2.35.2-42.0.1.el9.x86_64  \
	gcc-11.3.1-4.3.0.4.el9.x86_64 \
	gcc-c++-11.3.1-4.3.0.4.el9.x86_64 \
	glibc-2.34-100.0.1.el9_4.2.x86_64 \
	glibc-devel-2.34-100.0.1.el9_4.2.x86_64 \
	libaio-0.3.111-13.el9.x86_64 \
	libaio-devel-0.3.111-13.el9.x86_64 \
	libgcc-11.4.1-3.0.1.el9.x86_64 \
	libstdc++-11.3.1-4.3.0.4.el9.x86_64 \
	libstdc++-devel-11.3.1-4.3.0.4.el9.x86_64 \
	libnsl-2.34-100.0.1.el9_4.2.x86_64 \
	sysstat-12.5.4-7.0.1.el9.x86_64 \
	motif-2.3.4-28.el9.x86_64 \
	motif-devel-2.3.4-28.el9.x86_64 \
	openssl-3.0.7-27.0.3.el9.x86_64 \
	make-4.3-7.el9.x86_64 \
	xorg-x11-utils-7.5-40.el9.x86_64 \
	ksh-1.0.0~beta.1-3.0.1.el9.x86_64 \
	libcap-2.48-9.el9_2.x86_64 

printf "dnf upgrade and clean"
 dnf -y upgrade; dnf clean all
printf "install packages, upgrade, clean in $SECONDS sec\n\n"

# not needed anymore
# oraInst.loc will be in /oracle/Oracle
<<'EOF'
# add central inventory location file for next stage
printf "\nadd /etc/oraInst.loc as central inventory location file\n"
cat << 'CENTRAL_INV_LOC' > /etc/oraInst.loc
inventory_loc=/oracle/Oracle/oraInventory
inst_group=oracle
CENTRAL_INV_LOC
chmod ugo+r /etc/oraInst.loc
chmod go-w /etc/oraInst.loc
EOF

printf "Auto-save new image from current state of container\n"
CONTAINER_HOST_ID=`echo "$HOSTNAME"`
NEW_IMAGE_NAME="local/ol9-jdk21:pkgforms1412"
docker commit "$CONTAINER_HOST_ID" "$NEW_IMAGE_NAME"

printf "\nContainer auto-save new image: $NEW_IMAGE_NAME\n"

