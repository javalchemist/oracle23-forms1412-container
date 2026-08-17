#!/bin/bash


# install in oracle linux 9, packages required by Forms Builder installation

set -eu 
SECONDS=0
RESPONSE_FILE="/oracle/responseFile"
CENTRAL_INV="/oracle/Oracle/oraInst.loc"
INVENTORY_FILE_PATH="/oracle/oraInventory"
INSTALLATION_GROUP_NAME="oracle"
ORACLE_HOME="/oracle/Oracle/Middleware/Oracle_Home"


# ---------------- everything starts here 

# create central inventory location file 
mkdir Oracle
cat >> $CENTRAL_INV <<'EOF'
inventory_loc=/oracle/Oracle/oraInventory
inst_group=oracle
EOF
chmod ugo+r /oracle/Oracle/oraInst.loc
chmod go-w /oracle/Oracle/oraInst.loc

# start silent installation
printf "Launch Forms Builder installation package\n"
   /oracle/fmw_14.1.2.0.0_fr_linux64.bin -silent -responseFile "$RESPONSE_FILE" -logLevel Fine -ignoreSysPrereqs -invPtrLoc $CENTRAL_INV


printf "start Forms Builder Configuration Wizard\n"
 $ORACLE_HOME/forms/common/bin/config_builder.sh  autoconfig  formBuilderInstance=$ORACLE_HOME/formsInst1
 printf "Finish installation and configuration of Forms Builder 14.1.2 in $SECONDS sec\n"
 exit 0
#
#     ------------- end here
#