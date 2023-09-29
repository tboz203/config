# ~/.profile.d/wb_tools.sh

WB_TOOLS=$HOME/workspace/maxar/wb-team
if [[ -d $WB_TOOLS ]]; then
    # source $WB_TOOLS/source_all.sh
    source $WB_TOOLS/bash_lib/aws_tools/awsCreds.sh
    initaws() { awsCreds mcs-com us-east-1; }
else
    initaws() { echo "[X] wb_tools missing" ; }
    initaws
fi
