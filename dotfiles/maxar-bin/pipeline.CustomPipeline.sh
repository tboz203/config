#!/bin/bash

#
# Note: This script has a usage statement.  To see it, look for the usage() function below or
#       run this script with -h.
#

# The URL to the job in Jenkins
JENKINS_URL=https://jenkins-govcloud-utility-2.pipeline.awsgov.maxar.com

otherVars=(
  JENKINS_URL
  JOB_URL
  ENT_USER
  JENKINS_API_TOKEN
  useItarJob
)

jobParameters=(
  GIT_ORG
  GIT_REPO
  GIT_BRANCH
  GIT_HOST
  GIT_COMMIT
  GIT_SUBMODULES
  LANGUAGE
  RESOURCE_TYPE
  PIPELINE_PHASES
  IGNORE_PHASE_DEPENDENCIES
  PROD_GATE
  DISABLE_NOTIFICATIONS
  MALT_LOG_LEVEL
)

requiredParameters=(
  GIT_ORG
  GIT_REPO
  RESOURCE_TYPE
  ENT_USER
  JENKINS_API_TOKEN
)

GIT_HOST=${GIT_HOST:-github.digitalglobe.com}
GIT_BRANCH=${GIT_BRANCH:-master}
GIT_SUBMODULES=${GIT_SUBMODULES:-false}
LANGUAGE=${LANGUAGE:----}
RESOURCE_TYPE=${RESOURCE_TYPE:----}
IGNORE_PHASE_DEPENDENCIES=${IGNORE_PHASE_DEPENDENCIES:-true}
PROD_GATE=${PROD_GATE:-false}
DISABLE_NOTIFICATIONS=${DISABLE_NOTIFICATIONS:-false}
MALT_LOG_LEVEL=${MALT_LOG_LEVEL:-TRACE}
useItarJob=true

function usage() {
  additionalMessage="$1"
  echo "
  usage: $(basename $0) [OPTION VALUE]+
  where:
    OPTION   VALUE                                 Environment                Required
    -o       Name of org or namespace of project   GIT_ORG                     Yes
    -r       Name of repository                    GIT_REPO                    Yes
    -b       Name of repository branch             GIT_BRANCH                  One of GIT_BRANCH or GIT_COMMIT is required
    -g       Git server host name                  GIT_HOST                    Yes
    -c       Commit hash (overrides branch)        GIT_COMMIT                  One of GIT_BRANCH or GIT_COMMIT is required
    -S       Git submodules?                       GIT_SUBMODULES
    -I       Use ITAR version of job (true|false)
    -l       Code build language                   LANGUAGE
    -R       Resource type                         RESOURCE_TYPE               Yes
    -p       Pipeline phases                       PIPELINE_PHASES
    -D       Ignore phase dependencies             IGNORE_PHASE_DEPENDENCIES
    -P       Enable prod gate, if any              PROD_GATE
    -N       Disable notifications                 DISABLE_NOTIFICATIONS
    -L       Pipeline log level                    MALT_LOG_LEVEL
    -u       User name (in Jenkins)                ENT_USER                    Yes
    -t       Jenkins API token                     JENKINS_API_TOKEN           Yes
    -v       Increase verbosity of this script
    -h       Print this message

  Notes:
    - This script does not use the same defaults for PIPELINE_PHASES as the job itself. Unless specified, this
      script causes the job to run a full pipeline, as if all phases were enabled. Your
      pipeline-controls takes over in this case.
    - See parameter documentation here:
        ${JENKINS_URL}/job/Utility/job/P2020/job/pipeline.CustomPipeline/build
    - Valid choices for PIPELINE_PHASES are a comma-separated list of values from this list:
        build, test, scan, publish, ft, int, reg, prod, shared-services, suit01, devint
      An empty value will cause all active targets to be run, as in a build of a regularly onboarded branch.
    - Valid choices for RESOURCE_TYPE are one of:
        ami, cloud_foundry, container, dashboard, helm, library, pom, s3_terraform, terraform
    - Valid choices for LANGUAGE are one of:
        cpp, groovy, java, node, python, ruby, scala, terraform
    - This script will inherit some parameter values from the environment. See the 'Environment' column above.

  $(showParams)
  "
  test -n "${additionalMessage}" && echo -e "\n${additionalMessage}\n"
}

function showParams() {
  echo "Parameters:"
  printf '    %-30s %s\n' "-- Name --" "-- Current Value --"
  for p in ${otherVars[@]} ${jobParameters[@]}
  do
    eval local val=\${${p}}
    if [[ "${p}" = "JENKINS_API_TOKEN" && "${val}" != "" ]]
    then
      val='<redacted>'
    fi
    printf '    %-30s %s\n' "${p}" "${val}"
  done
}

function parameterCheck() {
  local fail=false
  for param in ${requiredParameters[@]}
  do
    eval local val=\${${param}}
    if [ -z "${val}" ]
    then
      echo -e "\e[1;33m The parameter ${param} is required.\e[0m"
      fail=true
    fi
  done

  if ${fail}
  then
    echo -e "\nSee output from\n  ${0} -h"
    exit 13
  fi
}

function makePayload() {
  PAYLOAD="{\"parameter\":["

  i=0
  while [ ${i} -lt ${#jobParameters[@]} ]
  do
    # we don't want a comma before the first item in the list.
    comma=','
    test ${i} -eq 0 && comma= 

    parameterName=${jobParameters[${i}]}
    eval local value=\${${parameterName}}
    local parameter="{\"name\":\"${parameterName}\",\"value\":\"${value}\"}"
    PAYLOAD="${PAYLOAD}${comma}${parameter}"
    let 'i += 1'
  done

  PAYLOAD="${PAYLOAD}]}"
}

verbosity=0
while getopts o:r:b:g:c:I:s:l:R:p:D:P:N:L:u:t:hv opt
do
  case ${opt} in
    o) GIT_ORG=${OPTARG};;
    r) GIT_REPO=${OPTARG};;
    b) GIT_BRANCH=${OPTARG};;
    g) GIT_HOST=${OPTARG};;
    c) GIT_COMMIT=${OPTARG};;
    s) GIT_SUBMODULES=${OPTARG};;
    I) useItarJob=${OPTARG};;
    l) LANGUAGE=${OPTARG};;
    R) RESOURCE_TYPE=${OPTARG};;
    p) PIPELINE_PHASES=${OPTARG};;
    l) LANGUAGE=${OPTARG};;
    D) IGNORE_PHASE_DEPENDENCIES=${OPTARGS};;
    N) DISABLE_NOTIFICATIONS=${OPTARG};;
    L) MALT_LOG_LEVEL=${OPTARG^^};;
    u) ENT_USER=${OPTARG};;
    t) JENKINS_API_TOKEN=${OPTARG};;
    v) let 'verbosity += 1';;
    h) usage; exit 0;;
    *) exit 1;;
  esac
done

if [ "${useItarJob}" = 'true' ]
then
  JOB_URL=${JENKINS_URL}/job/Utility/job/P2020/job/pipeline.CustomPipeline
elif [ "${useItarJob}" = 'false' ]
then
  JOB_URL=${JENKINS_URL}/job/Utility/job/NonITAR/job/P2020/job/pipeline.CustomPipeline/
else
  usage "ERROR: Did you specify a value other than 'true' or 'false' for the -I option?"
  exit 1
fi

BUILD_TRIGGER=${JOB_URL}/build

parameterCheck

# The user name and Jenkins API token used to authenticate with Jenkins
# For the Jenkins API token, see: ${JENKINS_URL}/user/${ENT_USER}/configure
AUTH_INFO="${ENT_USER}:${JENKINS_API_TOKEN}"

makePayload
test ${verbosity} -gt 2 && echo "Payload: $(echo ${PAYLOAD} | jq -C)"

if [ ${verbosity} -gt 0 ]
then
  showParams
  curlOpts=-i
  if [ ${verbosity} -gt 1 ]
  then
    curlOpts="${curlOpts} --verbose"
  fi
fi

echo -e "\nCalling curl: curl ${curlOpts} -XPOST ${BUILD_TRIGGER} ..."
curl ${curlOpts} -XPOST ${BUILD_TRIGGER} --user ${AUTH_INFO} --form "json=${PAYLOAD}"


echo -e "\nIf no error is reported above, look for your build here:\n  ${JOB_URL}\n"
