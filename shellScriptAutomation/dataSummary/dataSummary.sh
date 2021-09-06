#!/bin/bash

xmlOutFlag='N'
parentFolderName=$(echo $PWD | sed "s/.*\///g")

while [ $# -gt 0 ]
do
    case $1 in
        -xml|-XML)
            xmlOutFlag='Y'
            shift
        ;;
        *)
            shift
        ;;
    esac
done

if [ $xmlOutFlag == 'Y' ]
then
  cat >"./${parentFolderName}.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<modeling>
EOF
fi

numIdx=$(ls -l | grep 'dr.*x' | nl | awk '{printf $1RS}' | tail -1)
for ((i=1;i<=$numIdx;i++))
do
  folderName=$(ls -l | grep 'dr.*x' | nl | awk "NR==$i{printf \$10}")
  echo "-----------------------------------------------------------------"
  echo "Folder Name: $folderName"
  echo "-----------------------------------------------------------------"

  # Display E0 && mag
  echo "---------------------------"
  echo "Label:  E0 & mag"
  echo "---------------------------"
  cat ./$folderName/output.dat | grep 'E0'
  totalEnergyString=$(cat ./$folderName/output.dat | grep E0 | tail -1 | awk '{print $5}')
  totalEnergyNumber=$(echo $totalEnergyString | awk '{printf("%f",$0)}')
  totmag=$(cat ./$folderName/output.dat | grep E0 | tail -1 | awk '{print $10}')
  totAtomNum=$(cat ./$folderName/output.dat | grep "POSCAR found :" | awk '{print $7}')
  # Display EENTRO
  echo "---------------------------"
  echo "Label:  EENTRO"
  echo "---------------------------"
  eentro=$(cat ./$folderName/OUTCAR | grep EENTRO | tail -1 | awk '{printf $5}')
  echo "EENTRO =    $eentro"
  # Display whether accuracy is reached
  accuracyFlag=$(cat ./$folderName/OUTCAR | grep "aborting loop because EDIFF is reached")
  echo "---------------------------"
  echo "Label:  Accuracy Reached Check"
  echo "---------------------------"
  if [ -n "$accuracyFlag" ]
  then
      echo "Reached required accuracy"
  else
      echo -e "\033[31m Accuracy NOT reached!\033[0m"
  fi
  # Display external pressure
  echo "---------------------------"
  echo "Label:  External Pressure"
  echo "---------------------------"
  extPressure=$(cat ./$folderName/OUTCAR | grep "external pressure" | tail -1 | awk '{printf $4}')
  pullayStress=$(cat ./$folderName/OUTCAR | grep "external pressure" | tail -1 | awk '{printf $9}')
  echo "external pressure = $extPressure kB"
  echo "Pullay Stress =     $pullayStress kB"
  # Display Elapsed time
  echo "---------------------------"
  echo "Label:  Time"
  echo "---------------------------"
  elapsedTime=$(cat ./$folderName/OUTCAR | grep "Elapsed time" | tail -1 |  awk '{printf $4}')
  if [ -n "$elapsedTime" ]
  then
      echo "Elapsed time (sec): $elapsedTime"
  else
      echo -e "\033[31m Elapsed time NOT found!\033[0m"
  fi
  # Display Edisp (Energy with vdW corrections)
  echo "---------------------------"
  echo "Label:  Edisp"
  echo "---------------------------"
  edispFlag=$(cat ./$folderName/OUTCAR | grep Edisp | tail -1)
  if [ -n "$edispFlag" ]
  then
      edisp=$(cat ./$folderName/OUTCAR | grep Edisp | tail -1 | awk '{print $3}')
      echo "Edisp (eV):   $edisp"
  else
      edisp=0
      echo "Edisp (eV):   ---"
  fi
  # Display configuration message
  echo "---------------------------"
  echo "Label:  Configuration"
  echo "---------------------------"
  staticConf=$(grep "static configuration" ./$folderName/OUTCAR | awk '{print $8}')
  dynamicConf=$(grep "dynamic configuration" ./$folderName/OUTCAR | awk '{print $8}')
  magConf=$(grep "magnetic configuration" ./$folderName/OUTCAR | awk '{print $8}')
  echo "static configuration:   $staticConf"
  echo "dynamic configuration:  $dynamicConf"
  echo "magnetic configuration: $magConf"
  # Display details of magnetization
  echo "---------------------------"
  echo "Label:  Magnetization"
  echo "---------------------------"
  atomNumber=$(cat ./$folderName/output.dat | grep ions | awk '{print $7}' | head -1)
  afterNumber=$(echo "$atomNumber+5" | bc)
  tailNumber=$(echo "$afterNumber+1" | bc)
  cat ./$folderName/OUTCAR | grep -A $afterNumber "magnetization (x)" | tail -$tailNumber
  echo -e "\n"
  # Display Warning & Error Check
  echo "---------------------------"
  echo "Label:  Warning & Error Check"
  echo "---------------------------"
  tmpWarn=$(nl -b a ./$folderName/OUTCAR | sed -n '/WARNING/p' | awk '{for(i=2;i<=NF;i++){printf $i" "};printf"\n"}')
  errorMsg=$(cat ./$folderName/OUTCAR | grep -A 10 -B 5 ' EEEEE ')
  if [ -n "$errorMsg" ]
  then
      echo "Fatal message found in the ./$folderName/OUTCAR File:"
      cat ./$folderName/OUTCAR | grep -A 10 -B 5 ' EEEEE ' | sed -n '1,$p'
  else
      echo "No fatal error found in the ./$folderName/OUTCAR File."
  fi

  if [ -n "$tmpWarn" ]
  then
      nl -b a ./$folderName/OUTCAR | sed -n '/WARNING/p' | awk '{for(i=2;i<=NF;i++){printf $i" "};printf"\n"}'
  else
      echo "No WARNING found in the ./$folderName/OUTCAR File"
  fi
  echo -e "\n\n"
  # write xml file
  if [ $xmlOutFlag == 'Y' ]
  then
  cat >>"./${parentFolderName}.xml" <<EOF
    <summary name="$folderName">
        <totalEnergy>$totalEnergyNumber</totalEnergy>
	<totalmag>$totmag</totalmag>
        <totAtomNum>$totAtomNum</totAtomNum>
        <eentro>$eentro</eentro>
        <externalPressure>$extPressure</externalPressure>
        <pullayStress>$pullayStress</pullayStress>
        <elapsedTime>$elapsedTime</elapsedTime>
        <edisp>$edisp</edisp>
        <staticConfiguration>$staticConf</staticConfiguration>
        <dynamicConfiguration>$dynamicConf</dynamicConfiguration>
        <magneticConfiguration>$magConf</magneticConfiguration>
        <magmont>$(cat ./$folderName/OUTCAR | grep -A $afterNumber "magnetization (x)" | tail -$tailNumber | grep -v '^$' | grep -E "[0-9].*" | sed -E 's/^ +//g' | sed -E 's/ +/ /g')</magmont>
    </summary>
EOF
  fi

done

if [ $xmlOutFlag == 'Y' ]
  then
  echo '</modeling>' >>"./${parentFolderName}.xml"
fi
