#!/bin/bash
#Create pamameter delivery variables#
DeleteFlag='N'
UsedNodeNum=6
RunFlag='Y'
ProcessSurveillance='N'
PriorityFlag='N'
ParallelFlag='N'
TailFlag="N"
PlaneFlag='N'

while [ $# -gt 0 ]
do
    case $1 in
        -d|-D)
            DeleteFlag='Y'
            shift
        ;;
        [0-9]*)
            UsedNodeNum=$1
            shift
        ;;
        -b|-B)
            RunFlag='N'
            shift
        ;;
        -s|-S)
            ProcessSurveillance='Y'
            shift
        ;;
        -p|-P)
            PriorityFlag='Y'
            shift
        ;;
        -pe|-PE)
            ParallelFlag='Y'
            shift
        ;;
        -t|-T)
            TailFlag='Y'
            shift
        ;;
        -plane|-PLANE)
            PlaneFlag='Y'
            shift
        ;;
        *)
            shift
        ;;
    esac
done

#Create name of system#
SystemNameTemp=$(more INCAR | grep 'SYSTEM')
SystemName=${SystemNameTemp##*= }
if [ -z $SystemName ]
then
    SystemName='UnknownSystem'
fi

if [ $ParallelFlag = 'N' ]
then
    #Create cluster node selection information#
    qstat -f | cat | grep "/[0-$UsedNodeNum]/12\b\s*[0-9].*[^a]" >./machineList
    MachineListFile=$(pwd)'/machineList'
    sed -i "s/.*\(compute-0-[0-9]\+\).local/\1/g" ./machineList
    awk 'NR==FNR{a[$1] = $0}NR>FNR{ if($1 in a); else print $0 > "machineList"}' ~/apps/machineInfo/blackList ./machineList
    if [ $PriorityFlag = 'Y' ]
    then
        awk 'NR==FNR{a[$1] = $0}NR>FNR{ if($1 in a) print $0 > "machineList"}' ~/apps/machineInfo/priorityList ./machineList 
        if [ ! -s $MachineListFile ]
        then
            echo "Priority source temporarily not available"
            exit -1 
        fi
    fi

    if [ $TailFlag = 'Y' ]
    then
        NodeSelection=$(tail -1 ./machineList | awk '{printf $1}')
    else
        NodeSelection=$(head -1 ./machineList | awk '{printf $1}')
    fi
    #Create avaible number of nodes#
    CorePairTemp=$(more INCAR | grep 'NPAR')
    CorePair=$(echo $CorePairTemp | sed -E 's/.*([0-9]+).*/\1/')

    if [ -z $CorePair ]
    then
        CorePair=4
    fi

    if [ $TailFlag = 'Y' ]
    then
        CoreNum=$(tail -1 ./machineList | sed "s/.*[0-9]\/\([0-9]\+\)\/12.*/\1/g")
    else
        CoreNum=$(head -1 ./machineList | sed "s/.*[0-9]\/\([0-9]\+\)\/12.*/\1/g")
    fi

    if [ -z $CoreNum ]
    then
        echo "Source temporarily not available"
        exit -1
    fi
    TotalCoreNum=12
    CoreNum=$[$[$TotalCoreNum-$CoreNum]/$CorePair*$CorePair]

    #Switch vasp_std environment for 2D optimization#
    if [ $PlaneFlag = 'Y' ]
    then
        ProgramSelection='/home/yyzhao/vasp/vasp.5.4.4/bin/vasp_std'
    else
        ProgramSelection='/home/shke/DFT_SOFTWARE/vasp/vasp.5.4.4/bin/vasp_std'
    fi

    #Build standard run_vasp.sh file#
cat >run_vasp.sh <<EOF
#!/bin/bash
# bash started with bin/bash#

#$ -S /bin/bash
#$ -N $SystemName
# The Name of the exe file #

#$ -o stdout
# Standard output file name #

#$ -e stderr
# If error, recording file #

#$ -cwd
# Output file path #

#$ -j y
# Run instantly = yes #

#$ -V
# Synchronize environment to the calculation nodes #

#$ -pe mpich ${CoreNum}
# Number of CPU core in calculation #

#$ -l h=${NodeSelection}
# Name of cluster nodes in calculation #

ulimit -s unlimited

execmd=/home/shke/Ware/intel-2018/compilers_and_libraries_2018.3.222/linux/mpi/intel64/bin/mpirun

\$execmd -machinefile \$TMPDIR/machines -np \$NSLOTS ${ProgramSelection} 1>output.dat
EOF

else
    #Create cluster node selection information#
    qstat -f | cat | grep "/0/12\b\s*[0-9].*[^a]" >./machineList
    sed -i "s/.*\(compute-0-[0-9]\+\).local/\1/g" ./machineList
    awk 'NR==FNR{a[$1] = $0}NR>FNR{ if($1 in a); else print $0 > "machineList"}' ~/apps/machineInfo/blackList ./machineList
    if [ $PriorityFlag = 'Y' ]
    then
        awk 'NR==FNR{a[$1] = $0}NR>FNR{ if($1 in a) print $0 > "machineList"}' ~/apps/machineInfo/priorityList ./machineList 
        if [ ! -s $MachineListFile ]
        then
            echo "Priority source temporarily not available"
            exit -1
        fi
    fi

    if [ $TailFlag = 'Y' ]
    then
        NodeSelection_1=$(tail -2 ./machineList | sed -n "2p" | awk '{print $1}')
        NodeSelection_2=$(tail -2 ./machineList | sed -n "1p" | awk '{print $1}')
    else
        NodeSelection_1=$(head -2 ./machineList | sed -n "1p" | awk '{print $1}')
        NodeSelection_2=$(head -2 ./machineList | sed -n "2p" | awk '{print $1}')
    fi

    if [ -z $NodeSelection_1 -o -z $NodeSelection_2 ]
    then
        echo "Parallel source temporarily not available"
        exit -1
    fi

    #Switch vasp_std environment for 2D optimization#
    if [ $PlaneFlag = 'Y' ]
    then
        ProgramSelection='/home/yyzhao/vasp/vasp.5.4.4/bin/vasp_std'
    else
        ProgramSelection='/home/shke/DFT_SOFTWARE/vasp/vasp.5.4.4/bin/vasp_std'
    fi

    #Build standard run_vasp.sh file#
cat >run_vasp.sh <<EOF
#!/bin/bash
# bash started with bin/bash#

#$ -S /bin/bash
#$ -N $SystemName
# The Name of the exe file #

#$ -o stdout
# Standard output file name #

#$ -e stderr
# If error, recording file #

#$ -cwd
# Output file path #

#$ -j y
# Run instantly = yes #

#$ -V
# Synchronize environment to the calculation nodes #

#$ -pe mpich 24
# Number of CPU core in calculation #

#$ -l h=${NodeSelection_1}|${NodeSelection_2}
# Name of cluster nodes in calculation #

ulimit -s unlimited

execmd=/home/shke/Ware/intel-2018/compilers_and_libraries_2018.3.222/linux/mpi/intel64/bin/mpirun

\$execmd -machinefile \$TMPDIR/machines -np \$NSLOTS ${ProgramSelection} 1>output.dat
EOF
fi

chmod 775 ./run_vasp.sh
rm ./machineList

#Excution of run_vasp.sh#
if [ $RunFlag = 'Y' ]
then
    qsub ./run_vasp.sh
    if [ $ParallelFlag = 'N' ]
    then
        echo "Node Selection: $NodeSelection"
    else
        echo "Node Selection: ${NodeSelection_1} ${NodeSelection_2}"
    fi
fi

if [  $DeleteFlag = 'Y' ]
then
    $(rm ./run_vasp.sh)
fi

#ProcessSurveillance#
if [ $ProcessSurveillance = 'Y' ]
then
    date=$(date)
    jobID=$(qstat | tail -1 | awk '{print $1}')
    workDir=$(qstat -j $jobID | grep workdir | awk '{print $2}')
    nodeSelection=$(qstat -j $jobID | grep compute | awk '{print $3}' | sed -E s/hostname=//g)
    echo "$jobID    $nodeSelection    $workDir    $date" >>~/apps/machineInfo/surveillanceList
fi
