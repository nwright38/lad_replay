! /bin/bash

# Which spectrometer are we analyzing.
spec="lad_coin"
SPEC="LAD_COIN"

# What is the last run number for the spectrometer.
# The pre-fix zero must be stripped because ROOT is ... well ROOT
# lastRun=$( \
#     ls raw/"${spec}"_all_*.dat raw/../raw.copiedtotape/"${spec}"_all_*.dat -R 2>/dev/null | perl -ne 'if(/0*(\d+)/) {print "$1\n"}' | sort -n | tail -1 \
# )

#Need to fix file paths and names here once things are finalized.
lastRun=$( \
  ls /cache/hallc/c-lad/raw/lad_Production_no*.dat.* -R 2>/dev/null | perl -ne 'if(/0*(\d+)/) {print "$1\n"}' | sort -n | tail -1 \
)
#/volatile/hallc/c-lad/ehingerl/raw_data/LAD_cosmic/

# Which run to analyze.
runNum=$1
if [ -z "$runNum" ]; then
  runNum=$lastRun
fi

numEvents=$2

if [ -z "$numEvents" ]; then
  numEvents=50000
fi

numEventsk=$((numEvents / 1000))
# Which scripts to run.
script="SCRIPTS/${SPEC}/PRODUCTION/replay_production_lad_spec.C"
config="CONFIG/${SPEC}/PRODUCTION/${spec}_production.cfg"
expertConfig="CONFIG/${SPEC}/PRODUCTION/${spec}_production_expert.cfg"


# Define some useful directories
rootFileDir="./ROOTfiles/${SPEC}/${spec}50k"
monRootDir="./HISTOGRAMS/${SPEC}/ROOT"
monPdfDir="./HISTOGRAMS/${SPEC}/PDF"
reportFileDir="./REPORT_OUTPUT/${SPEC}"
reportMonDir="./UTIL_OL/REP_MON"
reportMonOutDir="./MON_OUTPUT/${SPEC}/REPORT"

# Name of the report monitoring file
reportMonFile="summary_output_${runNum}.txt"

# Which commands to run.
runHcana="hcana -q \"${script}(${runNum}, ${numEvents})\""
#runHcana="/home/cdaq/cafe-2022/hcana/hcana -q \"${script}(${runNum}, ${numEvents})\""
runOnlineGUI="panguin -f ${config} -r ${runNum}"
saveOnlineGUI="panguin -f ${config} -r ${runNum} -P"
saveExpertOnlineGUI="./online -f ${expertConfig} -r ${runNum} -P"
runReportMon="./${reportMonDir}/reportSummary.py ${runNum} ${numEvents} ${spec} singles"
openReportMon="emacs ${reportMonOutDir}/${reportMonFile}"

# Name of the replay ROOT file
replayFile="${spec}_replay_production_${runNum}"
rootFile="${replayFile}_${numEvents}.root"
latestRootFile="${rootFileDir}/${replayFile}_latest.root"

# Names of the monitoring file
monRootFile="${spec}_production_${runNum}.root"
monPdfFile="${spec}_production_${runNum}.pdf"
monExpertPdfFile="${spec}_production_expert_${runNum}.pdf"
latestMonRootFile="${monRootDir}/${spec}_production_latest.root"
latestMonPdfFile="${monPdfDir}/${spec}_production_latest.pdf"

# Where to put log
reportFile="${reportFileDir}/replay_${spec}_production_${runNum}_${numEvents}.report"
summaryFile="${reportFileDir}/summary_production_${runNum}_${numEvents}.txt"

# What is base name of panguin output.
outFile="${spec}_production_${runNum}"
outExpertFile="${spec}_production_expert_${runNum}"
outFileMonitor="output.txt"

# Replay out files
replayReport="${reportFileDir}/REPLAY_REPORT/replayReport_${spec}_production_${runNum}_${numEvents}.txt"

# Start analysis and monitoring plots.
{
  echo ""
  echo ":=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:="
  echo "" 
  date
  echo ""
  echo "Running ${SPEC} analysis on the run ${runNum}:"
  echo " -> SCRIPT:  ${script}"
  echo " -> RUN:     ${runNum}"
  echo " -> NEVENTS: ${numEvents}"
  echo " -> COMMAND: ${runHcana}"
  echo ""
  echo ":=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:="

  sleep 2
  eval ${runHcana}

  # Link the ROOT file to latest for online monitoring
  ln -fs ${rootFile} ${latestRootFile}

  sleep 2
  
  echo "" 
  echo ""
  echo ""
  echo ":=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:="
  echo ""
  echo "Running onlineGUI for analyzed ${SPEC} run ${runNum}:"
  echo " -> CONFIG:  ${config}"
  echo " -> RUN:     ${runNum}"
  echo " -> COMMAND: ${runOnlineGUI}"
  echo ""
  echo ":=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:="

  sleep 2
  cd onlineGUI
  eval ${runOnlineGUI}
  eval ${saveExpertOnlineGUI}
  pwd
  echo " ->file      ${outExpertFile}"
  echo "../HISTOGRAMS/${SPEC}/PDF/${outExpertFile}.pdf"
  mv "${outExpertFile}.pdf" "../HISTOGRAMS/${SPEC}/PDF/${outExpertFile}.pdf"
  cd ..
  ln -fs ${monExpertPdfFile} ${latestMonPdfFile}

###########################################################
# function used to prompt user for questions
function yes_or_no(){
  while true; do
    read -p "$* [y/n]: " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) echo "No entered" ; return 1 ;;
    esac
  done
}
# post pdfs in hclog
yes_or_no "Upload these plots to logbook HCLOG? " && \
    /site/ace/certified/apps/bin/logentry \
    -cert /home/cdaq/.elogcert \
    -t "${numEventsk}k replay plots for run ${runNum} TEST TEST TEST" \
    -e cdaq \
    -l TLOG \
    -a ${latestMonPdfFile} \

#    /home/cdaq/bin/hclog \
#    --logbook "HCLOG" \
#    --tag Autolog \
#    --title ${events}" replay plots for run ${runnum} TEST TEST TEST" \
#    --attach ${latestMonPdfFile} 
###########################################################
#    --title ${events}" replay plots for run ${runnum}" \

  echo "" 
  echo ""
  echo ""
  echo ":=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:="
  echo ""
  echo "Done analyzing ${SPEC} run ${runNum}."
  echo ""
  echo ":=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:="

  sleep 2

  echo "" 
  echo ""
  echo ""
  echo ":=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:="
  echo ""
  echo "Generating report file monitoring data file ${SPEC} run ${runNum}."
  echo ""
  echo ":=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:="

#  eval ${runReportMon}
#  mv "${outFileMonitor}" "${reportMonOutDir}/${reportMonFile}"
#  eval ${openReportMon}

  sleep 2

  echo ""
  echo ""
  echo ""
  echo ":=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:="
  echo ""
  echo "Taking hextuple ratios in  ${latestRootFile}"
  echo ""
  echo ":=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:="


#if [[ "${spec}" == "shms" ]]; then
#  ./hcana -l << EOF
#  .L ${shmsCounter}
#  run_el_counter_${spec}("${latestRootFile}");
#EOF
#fi
#if [[ "${spec}" == "hms" ]]; then
#  ./hcana -l << EOF
#  .L ${hmsCounter}
#  run_el_counter_${spec}("${latestRootFile}");
#EOF
#fi

  sleep 2

  echo ""
  echo ""
  echo ""
  echo "-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|"
  echo ""
  echo "Done!"
  echo ""
  echo "-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|"
  echo "" 
  echo ""
  echo ""

} 2>&1 | tee "${replayReport}"