#!/bin/bash

#
# build container for FormsBuilder 14.1.2.0

set -eu

usage() {
cat << EOF

Usage: $(basename "$0") -v VERSION [-h]"
   Builds a Forms Builder Image 

Parameters:
   -h: Usage instructions.Optional
   -v: FMW version.Required.Available choices: 14.1.2.0.
EOF
exit 0
}


# read CLI params
if [ "$#" -eq 0 ]; then usage; fi


# CLI parameters
VERSION=""

while getopts ":hv:" OPTION; do
case "$OPTION" in
    h)
      echo "  Builds docker container for Forms Builder 14.1.2.0. Uses oracleLinux 9, JDK 21. You must have available an oracle account to obtain install package for Forms Builder 14.1.2.0"
      exit 0
      ;;
    v)
      if [[ "$OPTARG" == "14.1.2.0" ]]; then
         VERSION="$OPTARG"
      else
         echo "Incorrect version $OPTARG"         
         usage 
         exit 1
      fi
      ;;
    :)
      echo "$OPTARG requires a value"; exit 1
      ;;
    ?)
    # covers the rest
      echo "Unknown choice while processing options. Available options are: -h -v"
      exit 1
      ;;
  esac
done

# self explanatory variables
INITIAL_IMAGE="oracle/jdk:21-ol9"
CONTAINER_PHASE1="ol9-pkgForms1412"
INSTALL_REQ_PKG="./install_req_pkgs.sh"

#        stage 1
# starts the initial container to obtaining a new updated image
#
stage1(){

# check if script is re-launch permaturely after a previous error
if docker inspect --format '{{.State.Running}}' "$CONTAINER_PHASE1" 2>/dev/null | grep -q 'true'; then
   echo -e "Container '$CONTAINER_PHASE1' is running. Should be stopped and removed.\n"
   exit 1
fi


# check image existence
if ! docker image inspect "$INITIAL_IMAGE" > /dev/null 2>&1; then
    echo "Image '$INITIAL_IMAGE' not found locally."
    exit 1
fi

# check container with same name
if docker container inspect "$CONTAINER_PHASE1" > /dev/null 2>&1; then
    echo "Container '$CONTAINER_PHASE1' already exist. Erase it or choose another name."
    exit 1
fi

set +e

printf "\nStart container with oracle Linux 9 and JDK 21 to install packages required  by Forms Builder 14.1.2.0\n"

# start container
docker run -i --rm --entrypoint "/bin/sh" -v /var/run/docker.sock:/var/run/docker.sock  -v /usr/bin/docker:/usr/bin/docker:ro --user root:root --workdir /home/oracle --name "$CONTAINER_PHASE1" --hostname "$CONTAINER_PHASE1" "$INITIAL_IMAGE" < "$INSTALL_REQ_PKG"

EXIT_CODE=$?
set -e
# in case something go wrong
if [ "$EXIT_CODE" -eq 0 ]; then
    printf 'Container phase 1: success\n'
else
    printf 'Container phase 1: failed (code: %d)\n' "$EXIT_CODE" >&2
    
    # description of ""docker run" error codes
    case "$EXIT_CODE" in
        125)
            printf 'Failure source: Docker daemon or client error\n' >&2
            ;;
        126)
            printf 'Failure source: Container command logic is not executable\n' >&2
            ;;
        127)
            printf 'Failure source: Container command logic not found\n' >&2
            ;;
        *)
            printf 'Failure source: Application-level fault inside container\n' >&2
            ;;
    esac
    exit "$EXIT_CODE"
fi

}
##       end stage 1


IMAGE_STAGE2="local/ol9-jdk21:pkgforms1412"
CONTAINER_PHASE2="FormsBuilder1412"
INSTALL_FORMSBUILDER="./install_config_forms.sh"
# this is where installation package should be and where installation will persist
VOLUME_HOST_PATH=""

#        stage 2
#  Start container from updated image
# install Forms Builder from installation package

stage2(){

# if script file is not update with non-empty value 
if [ -z "$VOLUME_HOST_PATH" ]; then
    printf 'Enter installation directory[example: /home/user/Forms1412]: '
    read -r VOLUME_HOST_PATH
fi

if [ -z "$VOLUME_HOST_PATH" ]; then
    printf 'Error: path not entered.\n' >&2
    exit 1
fi

# validate is absolute
case "$VOLUME_HOST_PATH" in
    /*) ;; # ok
     *)
   printf 'Error: Path "%s" is not absolute.\n' "$VOLUME_HOST_PATH" >&2
   exit 1
   ;;
esac

# validate path exist
if [ ! -d "$VOLUME_HOST_PATH" ]; then
   printf 'Error: Path "%s" does not exist or is not a directory.\n' "$VOLUME_HOST_PATH" >&2
   exit 1
fi

# check image existence
if ! docker image inspect "$IMAGE_STAGE2" > /dev/null 2>&1; then
    echo "Image '$IMAGE_STAGE2' not found locally."
    exit 1
fi

# check container with same name
if docker container inspect "$CONTAINER_PHASE2" > /dev/null 2>&1; then
    echo "Container '$CONTAINER_PHASE2' already exist. Erase it or choose another name."
    exit 1
fi

printf 'Installation will use directory: %s\n' "$VOLUME_HOST_PATH"

#
# starts container from  "stage1" image
printf "start container for installation and configuration\n"
docker run -i --user oracle:oracle --mount=type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock --mount=type=bind,source=/usr/bin/docker,target=/usr/bin/docker -v "$VOLUME_HOST_PATH":/oracle -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --workdir /oracle --name "$CONTAINER_PHASE2" --hostname "$CONTAINER_PHASE2" "$IMAGE_STAGE2" < "$INSTALL_FORMSBUILDER"

# full path of Forms Builder :
# /oracle/Oracle/Middleware/Oracle_Home/formsInst1/bin/frmbld.sh
printf "one line starter: \necho '/oracle/Oracle/Middleware/Oracle_Home/formsInst1/bin/frmbld.sh' | docker start -i FormsBuilder1412\n\n"
}
# end installing and configuring Forms Builder

#-----------------------------------------------------------------
#   start everything here
stage1
printf "\n----- end of stage 1 -----\n\n"

stage2
printf "\n----- end of stage 2 -----\n"

printf "\n----- end installation -----\n"

# end of file

