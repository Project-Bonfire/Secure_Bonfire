#/bin/bash



if [ -d results ]; then 
    results_dir=results
else
    results_dir=../../results
fi

latex_output_file="pir_results.tex"

xmin=8265000
xmax=17905000
ymin=0
ymax=50
seed=50

echo "\
\documentclass[serif,mathserif,final]{beamer}
\mode<presentation>{\usetheme{Lankton}}
\usepackage{amsmath,amsfonts,amssymb,pxfonts,eulervm,xspace}
\usepackage{graphicx}
\graphicspath{{figures/}}
\usepackage[orientation=landscape,size=custom,width=70,height=40,scale=.6,debug]{beamerposter}
\usepackage{tikz}
\usepackage{pgfplots}

%-- Header and footer information ----------------------------------
\\newcommand{\\footleft}{}
\\newcommand{\\footright}{}
\\title{PIR results}
\\author{Cesar G. Chaves}
\institute{Frankfurt University of Applied Sciences}
%-------------------------------------------------------------------
\pgfplotsset{compat=1.15}

\\newcommand{\\xmin}{$xmin}
\\newcommand{\\xmax}{$xmax}
\\newcommand{\\ymin}{$ymin}
\\newcommand{\\ymax}{$ymax}

%-- Main Document --------------------------------------------------
\\begin{document}

" > $results_dir/$latex_output_file


for results_file in $(ls -1 $results_dir/T_False*AD_3*3_T.txt | sort -t_ -nk6,6); do
    # ../../results/T_True_A_True_APL_15_AS_9_AD_3_log_summary_3_T.txt

    results_file_traffic=$(echo $results_file | sed "s/T_False/T_True/g")

    IFS='_' read -r -a file_name <<< "$results_file"
    traffic=${file_name[1]}
    attack=${file_name[3]}
    APL=${file_name[5]}
    AS=${file_name[7]}
    AD=${file_name[9]}


    for APIR in $(cat $results_file | cut -d' ' -f5 | sort -nu); do
    
        notraffic_file_name=$(echo "${results_file}${APIR}_" | sed "s/log_summary_3_T.txt//g")
        traffic_file_name=$(echo ${results_file_traffic}${APIR}_ | sed "s/log_summary_3_T.txt//g")

        if [ "$APIR" = "0.003" ] || [ "$APIR" = "0.004" ]; then
            continue
        fi

        # Secure - without traffic
        echo "packet_type PIR EPIR_TG EPIR_NI APIR EAPIR_TG EAPIR_NI - seed packet_id packet_size - Hsim_time Tsim_time Dsim_time - total_delay router local_delay - requests grants" > ${notraffic_file_name}S.csv
        awk -v v_apir=$APIR '{if ($1=="S" && $5==v_apir) print $0}' $results_file  >> ${notraffic_file_name}S.csv

        # Secure - with traffic
        echo "packet_type PIR EPIR_TG EPIR_NI APIR EAPIR_TG EAPIR_NI - seed packet_id packet_size - Hsim_time Tsim_time Dsim_time - total_delay router local_delay - requests grants" > ${traffic_file_name}S.csv
        awk -v v_apir=$APIR -v v_seed=$seed '{if ($1=="S" && $5==v_apir && $9==v_seed) print $0}' $results_file_traffic >> ${traffic_file_name}S.csv

        # Attack - without traffic
        echo "packet_type PIR EPIR_TG EPIR_NI APIR EAPIR_TG EAPIR_NI - seed packet_id packet_size - Hsim_time Tsim_time Dsim_time - total_delay router local_delay - requests grants" > ${notraffic_file_name}A.csv
        awk -v v_apir=$APIR '{if ($1=="A" && $5==v_apir) print $0}' $results_file >> ${notraffic_file_name}A.csv

        # Attack - with traffic
        echo "packet_type PIR EPIR_TG EPIR_NI APIR EAPIR_TG EAPIR_NI - seed packet_id packet_size - Hsim_time Tsim_time Dsim_time - total_delay router local_delay - requests grants" > ${traffic_file_name}A.csv
        awk -v v_apir=$APIR -v v_seed=$seed '{if ($1=="A" && $5 == v_apir && $9==v_seed) print $0}' $results_file_traffic  >> ${traffic_file_name}A.csv


#echo $results_file
#echo $results_file_traffic

#echo ${notraffic_file_name}S.csv 
#echo ${traffic_file_name}S.csv
#echo ${notraffic_file_name}A.csv
#echo ${traffic_file_name}A.csv


        echo "    

%################################################################################
  \\begin{frame}{}
      \\begin{block}{Secure - APL: $APL - APIR: ${APIR}xPIR - Traffic: False}
        \\begin{tikzpicture}
          \\begin{axis}[%
          width=1500, height=300, xmin=\\xmin, xmax=\\xmax, ymin=\\ymin, ymax=\\ymax,
            x tick label style={rotate=45, anchor=east},
            scaled ticks=false, tick label style={/pgf/number format/fixed},
            ylabel={Delay (Clock Cycles)}]

            \\addplot[ybar,bar width=0.01cm,fill=blue,draw=blue] %
	         table[x=Hsim_time,y=total_delay,col sep=space]{csv_files/$(basename ${notraffic_file_name})S.csv};

            \\addplot[ybar,bar width=0.01cm,fill=red,draw=red] %
                 table[x=Hsim_time,y=total_delay,col sep=space]{csv_files/$(basename ${notraffic_file_name})A.csv};

          \\end{axis}
        \\end{tikzpicture}
      \\end{block}

      %-- Block 1-2
      \\begin{block}{Secure - APL: $APL - APIR: ${APIR}xPIR - Traffic: True}
        \\begin{tikzpicture}
          \\begin{axis}[%
          width=1500, height=300, xmin=\\xmin, xmax=\\xmax, ymin=\\ymin, ymax=\\ymax,
            x tick label style={rotate=45, anchor=east},
            scaled ticks=false, tick label style={/pgf/number format/fixed},
            ylabel={Delay (Clock Cycles)}]

            \\addplot[ybar,bar width=0.01cm,fill=blue,draw=blue] %
	         table[x=Hsim_time,y=total_delay,col sep=space]{csv_files/$(basename ${traffic_file_name})S.csv};

            \\addplot[ybar,bar width=0.01cm,fill=red,draw=red] %
                 table[x=Hsim_time,y=total_delay,col sep=space]{csv_files/$(basename ${traffic_file_name})A.csv};

          \\end{axis}
        \\end{tikzpicture}
      \\end{block}
\\end{frame}
%################################################################################

        " >> $results_dir/$latex_output_file

    done
done

echo "\\end{document}" >> $results_dir/$latex_output_file
