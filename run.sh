#!/bin/bash
set -ei

declare -x LDB_PATH="/mnt/beegfs/pipelines/cel-cnv-eacon/pipeline/databases"
declare -x PROFILE="/mnt/beegfs/pipelines/cel-cnv-eacon/pipeline/cel-cnv-eacon/.igr/profiles/slurm"
declare -x PIPELINE_PATH="/mnt/beegfs/pipelines/cel-cnv-eacon/pipeline/cel-cnv-eacon"
declare -x ENV_PATH="/mnt/beegfs/pipelines/rna-count-salmon/env"
declare -x SNAKEMAKE_OUTPUT_CACHE="/mnt/beegfs/pipelines/cel-cnv-eacon/cache/"
export LDB_PATH PROFILE PIPELINE_PATH ENV_PATH SNAKEMAKE_OUTPUT_CACHE

# This function only changes echo headers
# for user's sake.
function message() {
  # Define local variables
  local status=${1}         # Either INFO, CMD, ERROR or DOC
  local message="${2:-1}"   # Your message

  # Classic switch based on status
  if [ ${status} = INFO ]; then
    echo -e "\033[1;36m@INFO:\033[0m ${message}"
  elif [ ${status} = WARNING ]; then
    echo -e "\033[1;33m@WARNING:\033[0m ${message}"
  elif [ ${status} = ERROR ]; then
    echo -e "\033[41m@ERROR:\033[0m ${message}"
  elif [ ${status} = DOC ]; then
    echo -e "\033[0;33m@DOC:\033[0m ${message}"
  else
    error_handling ${LINENO} 1 "Unknown message type"
  fi
}

# This function will take error messages and exit the program
function error_handling() {
  # Geathering input parameter (message, third parameter is optionnal)
  echo -ne "\n"
  local parent_lineno="$1"
  local code="$2"
  local message="${3:-1}"

  # Checking the presence or absence of message
  if [[ -n "$message" ]] ; then
    # Case message is present
    message ERROR "Error on or near line ${parent_lineno}:\n ${message}"
    message ERROR "Exiting with status ${code}"
  else
    # Case message is not present
    message ERROR "Error on or near line ${parent_lineno}"
    message ERROR "Exiting with status ${code}"
  fi

  # Exiting with given error code
  exit "${code}"
}

function help_message() {
  message DOC "Hi, I'm functionnal only at IGR's Flamingo. Do not try to run "
  message DOC "me elsewhere. I won't work."
  echo ""
  message DOC "Thanks for using me as your script for running "
  message DOC "rna-count-salmon I'm very proud to be your script today,"
  message DOC "and I hope you'll enjoy working with me."
  echo ""
  message DOC "Every time you'll see a line starting with '@', "
  message DOC "it will be because I speak."
  message DOC "In fact, I always start my speech with :"
  message DOC "'\033[0;33m@DOC:\033[0m' when i't about my functions,"
  message DOC "'\033[1;36m@INFO:\033[0m' when it's about my intentions, "
  message DOC "'\033[41m@ERROR:\033[0m', I tell you when things go wrong."
  echo ""
  message DOC "I understand very fiew things, and here they are:"
  message DOC "-h | --help        Print this help message, then exit."
  message DOC "Otherwise, run me without any arguments and I'll do magic."
  echo ""
  message DOC "I have error codes and here are their meaning:"
  message DOC "0 - No problem at all"
  message DOC "1 - Conda environment error (source failed or command not found)"
  message DOC "2 - Conda activation error"
  message DOC "3 - Pipeline not found (path error, environment error)"
  message DOC "4 - Configuration error (cold_storage, design or config)"
  message DOC "5 - Dependencies missing (path error, environment error)"
  message DOC "6 - Snakemake error"
  echo ""
  message DOC "A typical command line would be:"
  message DOC "bash /path/to/run.sh"
  exit 0
}

function prepare_cold_storage() {
  python3 "${PIPELINE_PATH:?}/scripts/prepare_cold_storage.py" --path /mnt/{isilon,nfs01,install} && message INFO "Cold storage mounting points defined." || error_handling "${LINENO}" 4 "Could not build cold storage yaml file"
}

function prepare_design() {
    python3 "${PIPELINE_PATH:?}/scripts/prepare_design.py" -r "${PWD}" && message INFO "Design file built." || error_handling "${LINENO}" 4 "Could not build design tsv file"
}

function prepare_config() {
    python3 "${PIPELINE_PATH:?}/scripts/prepare_config.py" -r "${PWD}" --ldb "${LDB_PATH:?}" --threads 100  && message INFO "Configuration file built" || error_handling "${LINENO}" 4 "Could not create configuration yaml file"
}

function upload() {
    local UPDIR="results_to_upload/$(basename ${PWD})"
    mkdir --parents --verbose "${UPDIR}"
    find -maxdepth 1 -type d |while read DIR; do [[ $(basename ${DIR}) =~ ^\.|results_to_upload ]] || mv --verbose "${DIR}" "${UPDIR}"; done
    module load java/1.8.0_181
    message INFO "On prompt, enter your password in order to upload your results to NextCloud"
    java -jar /mnt/beegfs/userdata/g_jules-clement/agent-nextcloud/agent-nextcloud-1.0.2.jar UPLOAD results_to_upload Onco_Cyto "${USER}"
}



[[ $# -gt 0 ]] && help_message

CONDA='conda'
CONDA_VERSION="$(conda --version)"
[ "${CONDA_VERSION:?}" = "conda 4.9.2" ] || message WARNING "Your version of conda might not be up to date. Trying anyway with the rest of the pipeline."
which mamba > /dev/null 2>&1 && CONDA="mamba" || message WARNING "Mamba not found, falling back to conda."

# Loading conda
message INFO "Sourcing conda for users who did not source it before."
source "$(conda info --base)/etc/profile.d/conda.sh" && conda activate || exit error_handling "${LINENO}" 1 "Could not source conda environment."

# Activate environment
message INFO "Loading ${ENV_PATH:?} environment"
conda activate "${ENV_PATH:?}" || error_handling "${LINENO}" 2 "Could not activate the conda environment."

# then installation process did not work properly
message INFO "Running pipeline if and only if it is possible"
if [ -z ${PIPELINE_PATH} ]; then
  error_handling "${LINENO}" 3 "Environment was not suitable for this pipeline." 
else
  PATH="${PATH}:${PIPELINE_PATH:?}/scripts/"
  export PATH

  # Building multiple configurations files
  [ -f cold_storage.yaml ] && message INFO "Cold storage mounting points already provided." || prepare_cold_storage
  [ -f design.tsv ] && message INFO "Design file already provided." || prepare_design
  [ -f config.yaml ] && message INFO "Configuration file already provided." || prepare_config

  # Running pipeline
  type grd &> /dev/null && message INFO "Environment suitable" || error_handling "${LINENO}" 5 "grd was not available in path"
  snakemake -s "${PIPELINE_PATH:?}/Snakefile" --configfile config.yaml --profile "${PROFILE:?}" && message INFO "Process now over!" || error_handling "${LINENO}" 6 "Failed with Snakemake process"
  upload && message INFO "Upload successful" || error_handling "${LINENO}" 7 "Could not upload results"
fi

message INFO "Process over"
exit 0
