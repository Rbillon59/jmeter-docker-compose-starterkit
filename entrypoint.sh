#!/bin/bash

set -e

NOW=$(date +"%Y%m%d-%H%M%S")
JMETER_HOME="/opt/jmeter"


if [ -z "${JMX}" ]; then
   echo "Give at least the jmx file name as parameter with"
   echo "JMX=my-scenario.jmx docker-compose up -d" 
   exit 1
fi

# Environment variable available :

if [ -z "${host}" ]; then
    host=jsonplaceholder.typicode.com
fi

if [ -z "${protocol}" ]; then
    protocol=https
fi

if [ -z "${port}" ]; then
    port=443
fi

if [ -z "${XMX}" ]; then
    XMX="1g"
fi

if [ -z "${XMS}" ]; then
    XMS="1g"
fi

cp /scenario/* /opt/jmeter/bin

# Setting report and log dir
LOGS_DIR="/opt/jmeter/logs"
RESULTS_DIR="/opt/jmeter/results"
RESULTS_FILE="${RESULTS_DIR}/${NOW}-load-test-${JMX}-result.csv"

# Preparing JMeter vars
JMX_FILE_PATH="${JMETER_HOME}/bin/${JMX}"
PARAM_HOSTS_ARGS="-Jhost=${host} -Jport=${port} -Jprotocol=${protocol}"
PARAM_USERS_ARGS="-Jthreads=${threads} -Jduration=${duration} -Jrampup=${rampup} -Jjmx=${JMX}"

# JVM args
JVM_ARGS="$JVM_ARGS -Duser.timezone=CET"
JVM_ARGS="$JVM_ARGS -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false"
JVM_ARGS="$JVM_ARGS -Dcom.sun.management.jmxremote.authenticate=false"
JVM_ARGS="$JVM_ARGS -Dcom.sun.management.jmxremote.ssl=false"
JVM_ARGS="$JVM_ARGS -XX:+UseThreadPriorities -XX:ThreadPriorityPolicy=42"
JVM_ARGS="$JVM_ARGS -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Xms${XMX} -Xmx${XMS} -XX:G1ReservePercent=20 -Xss256k"
export JVM_ARGS


# Runtime

CSV=$(find ./data -maxdepth 1 -type f -name "*.csv")

if [[ -z "${SLAVE}" ]]; then
    # Building host list
        START=1
        END=${nbInjector}
        i=${START}
        HOST_LIST=()

        while [[ ${i} -le ${END} ]]; do
            HOST_LIST+=("jmeter_jmeter-slave_${i}")
            i=$((i + 1))
        done

        echo "Injector hostname list : ${HOST_LIST[@]}"

        # Building IP list of slaves
        for HOST in "${HOST_LIST[@]}"; do
            HOST_IP_LIST+=( "$(getent hosts "${HOST}" | awk -F" " '{print $1}')" )
        done

        echo "Injectors IP list : ${HOST_IP_LIST[@]}"
fi

if [[ -n "${CSV}" ]]; then
    if [[ "${SLAVE}" -eq 1 ]]; then
        sleep $((2 * nbInjector))

        IP=$(hostname -i)

        ls /data/split/*"${IP}"

        for DATASET_FILE_PATH in $(ls /data/split/*"${IP}"); do
            DATASET_FILE=$(basename "${DATASET_FILE_PATH}")
            echo "copying ${DATASET_FILE_PATH} to /opt/jmeter/bin/${DATASET_FILE/.${IP}/}"
            cp "${DATASET_FILE_PATH}" "/opt/jmeter/bin/${DATASET_FILE/.${IP}/}"
        done

        ls -ltra /opt/jmeter/bin/*.csv

    else

        echo "Found csv dataset to split"
        echo "Controller dataset management starting"

        # Dataset splitting
        mkdir -p /data/split
        
        START=0
        END=$((nbInjector -1))
        i=${START}

        # Splitting dataset to equal parts
        for DATASET_FILE_PATH in $(ls /data/*.*); do
            DATASET_FILE=$(basename "${DATASET_FILE_PATH}")
            TOTAL_LINE=$(wc -l < "${DATASET_FILE_PATH}")
            LINES_PER_FILES=$(((TOTAL_LINE + nbInjector - 1) / nbInjector))
            split -d -a 1 -l ${LINES_PER_FILES} "${DATASET_FILE_PATH}" "/data/split/splitted_${DATASET_FILE}"

            echo "Split folder content"
            ls -ltra /data/split

            # Appending slave IP to dataset file 
            while [[ "${i}" -le ${END} ]]; do
                echo "Generating dataset for ${HOST_IP_LIST[${i}]}"
                mv "/data/split/splitted_${DATASET_FILE}${i}" "/data/split/${DATASET_FILE}.${HOST_IP_LIST[${i}]}"
                i=$((i + 1))
            done
        done

        ls -ltra /data/split
    fi
    else 
    echo "No dataset found, starting JMeter..."
fi

if [[ "${SLAVE}" -eq 1 ]]; then

    echo "Starting JMeter on slave ${IP}"

    LOG_FILE="${LOGS_DIR}/jmeter-${IP}-${JMX}-${NOW}.log"

    set -x

    ${JMETER_HOME}/bin/jmeter-server \
    -LINFO -n -X \
    -j ${LOG_FILE} \
    -d ${JMETER_HOME} \
    -Jserver.exitaftertest=true \
    ${PARAM_HOSTS_ARGS} \
    ${PARAM_USERS_ARGS}

else 

    echo "Starting JMeter on controller"

    sleep $((2 * nbInjector))

    printf -v SLAVE_IP_LIST '%s,' "${HOST_IP_LIST[@]}"
    LOG_FILE="${LOGS_DIR}/jmeter-master-${JMX}-${NOW}.log"

    echo "Slaves IP :"
    echo "${SLAVE_IP_LIST::-1}"

    set -x

    ${JMETER_HOME}/bin/jmeter \
    -LINFO \
    -d ${JMETER_HOME} \
    -n -j ${LOG_FILE} \
    -l ${RESULTS_FILE} \
    -R ${SLAVE_IP_LIST::-1} \
    ${PARAM_HOSTS_ARGS} \
    ${PARAM_USERS_ARGS} \
    -t ${JMX_FILE_PATH} \
    -e \
    -o ${RESULTS_DIR}/report-${JMX}-${NOW}

    trap "sh ${JMETER_HOME}/bin/stoptest.sh" EXIT
fi
