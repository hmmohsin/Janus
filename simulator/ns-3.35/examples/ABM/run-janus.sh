#!/bin/bash
source config.sh
DIR="$NS3/examples/ABM"
DUMP_DIR="$DIR/dump_janus"

DT=101
FAB=102
CS=103
IB=104
ABM=110

RENO=0
CUBIC=1
DCTCP=2
HPCC=3
POWERTCP=4
HOMA=5
TIMELY=6
THETAPOWERTCP=7

BUF_ALGS=($DT $FAB $CS $IB $ABM)
TCP_ALGS=($CUBIC $DCTCP $TIMELY $POWERTCP)

SERVERS=32
LEAVES=2
SPINES=2
LINKS=4
SERVER_LEAF_CAP=10
LEAF_SPINE_CAP=10
LATENCY=25

RED_MIN=65
RED_MAX=65

N_PRIO=2

ALPHAFILE="$DIR/alphas"
CDFFILE="$NS3/workload/das.txt"
CDFNAME="DAS"
echo $CDFFILE
ALPHA_UPDATE_INT=1 # 1 RTT


STATIC_BUFFER=0
# BUFFER=$(( 1000*1000*9  ))
BUFFER_PER_PORT_PER_GBPS=9.6 # https://baiwei0427.github.io/papers/bcc-ton.pdf (Trident 2)
BUFFER=$(python3 -c "print(int($BUFFER_PER_PORT_PER_GBPS*1024*($SERVERS+$LINKS*$SPINES)*$SERVER_LEAF_CAP))")

TCP=$CUBIC

START_TIME=10
END_TIME=24
FLOW_END_TIME=13


cd $NS3


N=0

##################################################################################
# Cubic, DCTCP run websearch workload, and Theta-PowerTCP runs incast workload@ 30% buffer size and request rate of 2.
# Cubic, DCTCP and Theta-PowerTCP are separated to 3 different queues.
# The idea is to observe how Cubic load effects DCTCP and PowerTCP even though they do not share queues. They do share the same buffer though.
##################################################################################

# Total simulations =  12 
SERVERS=32
LEAVES=2
SPINES=2
LINKS=4
SERVER_LEAF_CAP=10
LEAF_SPINE_CAP=10
LATENCY=10

N_PRIO=8
BURST_SIZES=0.3
BURST_SIZE=$(python3 -c "print($BURST_SIZES*$BUFFER)")
BURST_FREQ=2
DCTCPLOAD=0.0
POWERLOAD=0.0
TCP=$CUBIC #this wont be used anyway
ALG=$DT
for LOAD in 0.2;do
    FLOW_END_TIME=12 #$(python3 -c "print(10+3*0.8/$LOAD)")
    FLOWFILE="$DUMP_DIR/fcts-multi-$TCP-$ALG-$LOAD-$BURST_SIZES-$BURST_FREQ.fct"
    TORFILE="$DUMP_DIR/tor-multi-$TCP-$ALG-$LOAD-$BURST_SIZES-$BURST_FREQ.stat"
    N=$(( $N+1 ))
    #(time ./waf --run janus-das --gdb)
    #(time ./waf --run janus-das --gdb)&

    (time ./waf --run "janus-das --load=$LOAD  --StartTime=$START_TIME --EndTime=$END_TIME --FlowLaunchEndTime=$FLOW_END_TIME --serverCount=$SERVERS --spineCount=$SPINES --leafCount=$LEAVES --linkCount=$LINKS --spineLeafCapacity=$LEAF_SPINE_CAP --leafServerCapacity=$SERVER_LEAF_CAP --linkLatency=$LATENCY --TcpProt=$TCP --BufferSize=$BUFFER --statBuf=$STATIC_BUFFER --algorithm=$ALG --RedMinTh=$RED_MIN --RedMaxTh=$RED_MAX --request=$BURST_SIZE --queryRequestRate=$BURST_FREQ --nPrior=$N_PRIO --alphasFile=$ALPHAFILE --cdfFileName=$CDFFILE --alphaUpdateInterval=$ALPHA_UPDATE_INT --fctOutFile=$FLOWFILE --torOutFile=$TORFILE"; echo "$FLOWFILE" --gdb)&
    while [[ $(( $(ps aux | grep janus-das-optimized | wc -l)+$(ps aux | grep janus-das-optimized | wc -l) )) -gt $N_CORES ]];do
        sleep 30;
        echo "waiting for cores, $N running..."
    done
    sleep 100
done

while [[ $(ps aux|grep "janus-das-optimized"|wc -l) -gt 1 ]];do
	echo "Waiting for simulations to finish..."
	sleep 5
done


echo "##################################"
echo "#      FINISHED EXPERIMENTS      #"
echo "##################################"
