cd $(dirname $(realpath $0))

export SCRIPT_DIR=$(pwd)

source ${SCRIPT_DIR}/global-variables.sh
source ${SCRIPT_DIR}/user-variables.sh

info() {
    printf "$*\n"
}

wait_to_continue() {
    info "Press any key to continue"
    read -n 1
    info "\n\n\n"
}

SCRIPT_STAGE=${1:-pre_install}

INSTRUCTIONS_PATH="instructions/${SCRIPT_STAGE}"

for instruction in $(find ${INSTRUCTIONS_PATH} | sort); do
    [[ -f $instruction ]] && {
        instruction_path="$(realpath $instruction)"
        echo "executing: $instruction_path"
        #bash ./$instruction || wait_to_continue
        echo "finished:  $instruction_path"
    }
done

exit 0
