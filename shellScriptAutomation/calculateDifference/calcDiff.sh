#!/bin/sh

# Initialing variables
folderName=$(pwd)
atomNumber=''
selectiveFlag='N'

while [ $# -gt 0 ]
do
    case $1 in
        [0-9]*)
                atomNumber=$1
                shift
        ;;
	-s|-S)
		selectiveFlag='Y'
		shift
	;;
        *)
                shift
        ;;
    esac
done

if [ -z $atomNumber ]
then
    outExistFlag=$(ls $folderName | grep output.dat)
    if [ -z $outExistFlag ]
    then 
	echo "output.dat not found, input atom number as parameters or output.dat file"
	echo "exiting"
	exit
    else
        atomNumber=$(cat $folderName/output.dat | grep ions | awk '{print $7}')
    fi
fi
dataNumber=0
for ((i=3;i<=5;i++))
do
    latticePos[$dataNumber]=$(sed -n ""$i"p" $folderName/POSCAR | awk '{printf $1}')
    latticePos[$dataNumber+1]=$(sed -n ""$i"p" $folderName/POSCAR | awk '{printf $2}')
    latticePos[$dataNumber+2]=$(sed -n ""$i"p" $folderName/POSCAR | awk '{printf $3}')
    dataNumber=$dataNumber+3;
done

dataNumber=0
for ((i=3;i<=5;i++))
do
    latticeCont[$dataNumber]=$(sed -n ""$i"p" $folderName/CONTCAR | awk '{printf $1}')
    latticeCont[$dataNumber+1]=$(sed -n ""$i"p" $folderName/CONTCAR | awk '{printf $2}')
    latticeCont[$dataNumber+2]=$(sed -n ""$i"p" $folderName/CONTCAR | awk '{printf $3}')
    dataNumber=$dataNumber+3;
done

latticeLength=${#latticePos[*]}
for ((i=0;i<$latticeLength;i++))
do
    cmpVec[0]=${latticePos[$i]}
    cmpVec[1]=${latticeCont[$i]}
    latticeDiff[$i]=$(echo "${cmpVec[@]}" | awk '{if($1==0) print "-.----------------"; else printf "%.16f",($2-$1)/$1*100}')
done

dataNumber=0
if [ $selectiveFlag = 'Y' ]
then
    initLine=10
else
    iniLine=9
fi

for ((i=$iniLine;i<$iniLine+$atomNumber;i++))
do
    atomPos[$dataNumber]=$(sed -n ""$i"p" $folderName/POSCAR | awk '{printf $1}')
    atomPos[$dataNumber+1]=$(sed -n ""$i"p" $folderName/POSCAR | awk '{printf $2}')
    atomPos[$dataNumber+2]=$(sed -n ""$i"p" $folderName/POSCAR | awk '{printf $3}')
    dataNumber=$dataNumber+3;
done   

dataNumber=0
for ((i=$((iniLine+0));i<$iniLine+$atomNumber;i++))
do
    atomCont[$dataNumber]=$(sed -n ""$i"p" $folderName/CONTCAR | awk '{printf $1}')
    atomCont[$dataNumber+1]=$(sed -n ""$i"p" $folderName/CONTCAR | awk '{printf $2}')
    atomCont[$dataNumber+2]=$(sed -n ""$i"p" $folderName/CONTCAR | awk '{printf $3}')
    dataNumber=$dataNumber+3;
done

atomLength=${#atomPos[*]}
for ((i=0;i<$atomLength;i++))
do
    cmpVec[0]=${atomPos[$i]}
    cmpVec[1]=${atomCont[$i]}
    atomDiff[$i]=$(echo "${cmpVec[@]}" | awk '{if($1==0) print "-.----------------"; else printf "%.16f",($2-$1)/$1*100}')
done

# Create Lattice Report
cat <<EOF
----------------------------------------------------------------------------------------------------
Lattice Difference
----------------------------------------------------------------------------------------------------
Direction   |           x                   y                       z
--------------------------------------------------------------------------------------
a-POSCAR    |   ${latticePos[0]}   ${latticePos[1]}   ${latticePos[2]} 
a-CONTCAR   |   ${latticeCont[0]}   ${latticeCont[1]}   ${latticeCont[2]}
a-Diff (%)  |   ${latticeDiff[0]}   ${latticeDiff[1]}   ${latticeDiff[2]}
--------------------------------------------------------------------------------------
b-POSCAR    |   ${latticePos[3]}   ${latticePos[4]}   ${latticePos[5]}
b-CONTCAR   |   ${latticeCont[3]}   ${latticeCont[4]}   ${latticeCont[5]}
b-Diff (%)  |   ${latticeDiff[3]}   ${latticeDiff[4]}   ${latticeDiff[5]}
--------------------------------------------------------------------------------------
c-POSCAR    |   ${latticePos[6]}   ${latticePos[7]}   ${latticePos[8]}
c-CONTCAR   |   ${latticeCont[6]}   ${latticeCont[7]}   ${latticeCont[8]}
c-Diff (%)  |   ${latticeDiff[6]}   ${latticeDiff[7]}   ${latticeDiff[8]}
--------------------------------------------------------------------------------------


EOF

# Create Atom Position Report
cat <<EOF
----------------------------------------------------------------------------------------------------
Atom Position Difference
----------------------------------------------------------------------------------------------------
Direction   |           x                   y                       z
--------------------------------------------------------------------------------------
EOF

for ((i=1;i<=$atomNumber;i++))
do
numIdx=$(echo "3*($i-1)" | bc)
cat <<EOF
$i-POSCAR    |   ${atomPos[$numIdx]}   ${atomPos[$numIdx+1]}   ${atomPos[$numIdx+2]}
$i-CONTCAR   |   ${atomCont[$numIdx]}   ${atomCont[$numIdx+1]}   ${atomCont[$numIdx+2]}
$i-Diff (%)  |   ${atomDiff[$numIdx]}   ${atomDiff[$numIdx+1]}   ${atomDiff[$numIdx+2]}
--------------------------------------------------------------------------------------
EOF

done
