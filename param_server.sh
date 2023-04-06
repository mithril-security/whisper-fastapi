#!/bin/bash

# We parameterize the server with the following parameters:
max_batch_size=(2 4 8 16 32 64)
max_latency_ms=($(seq 10000 10000 60000))

# Start the server in a new shell and return it's PID so we can kill it later
start_server() {
    # Start the server
    echo "Starting server with max_batch_size=$1 and max_latency_ms=$2"
    python server.py --max_batch_size $1 --max_latency_ms $2 & 2>&1 > /dev/null
    SERVER_PID=$!
    echo "Server PID: $SERVER_PID"
    # Wait until the PORT is open
    while [ -z "$(lsof -i | grep -E "8000" | awk -F':' '{print $2}' | awk '{print $1}')" ];
    do
        sleep 0.5;
    done
}

# Kill the server
kill_server() {
    echo "Killing server with PID: $SERVER_PID"
    kill -9 $SERVER_PID
    sleep 3
}

__exit() {
    kill_server
    exit 1
}

choose_batch_size_and_latency() {
    random=`date +%s%N | cut -b10-13 | sed -e "s/^0//"`
    # Choose a random batch size and latency
    
    batch_index=`python -c "import random; get_random = lambda: random.randint(0, ${#max_batch_size[@]} - 1); vals=[get_random() for i in range(100)]; print(vals[int(\"$random\") % 100])"`

    local batch_size=${max_batch_size[$((batch_index))]}
    latency_index=`python -c "import random; get_random = lambda: random.randint(0, ${#max_latency_ms[@]} - 1); vals=[get_random() for i in range(100)]; print(vals[int(\"$random\") % 100])"`
   

    local latency=${max_latency_ms[$((latency_index))]}
    echo $batch_size $latency
}
# Run the benchmark
run_benchmark() {
    # Run the `tester.sh` script
    # If no arguments are provided for sheet_name and profiler_file,
    # use the default values
    
    if [ -z "$1" ]
    then
        local sheet_name="FastAPI-Whisper-Server-Results"
    else
        local sheet_name=$1
    fi
    
    if [ -z "$2" ]
    then
        local profiler_file="profiler.json"
    else
        local profiler_file=$2
    fi
    
    # Run the benchmark randomly for 10 times
    for i in {1..100}
    do
        local batch_size=$(choose_batch_size_and_latency | awk '{print $1}')
        local latency=$(choose_batch_size_and_latency | awk '{print $2}')

        printf "\n\tRunning benchmark with batch_size=%s and latency=%s\n" $batch_size $latency
        start_server $batch_size $latency || __exit
        ../benchmarker/tester.sh $sheet_name $profiler_file || __exit
        # Get Process ID of the tester.sh script
        local tester_pid=`ps -ef | grep tester.sh | grep -v grep | awk '{print $2}'`

        # Set up a background process to kill the server and tester.sh script if the 
        # benchmark goes beyound 10 minutes
        (sleep 300; kill -9 $SERVER_PID $tester_pid) &
        kill_server
    done
    
}

run_benchmark $1 $2
trap __exit SIGINT SIGTERM