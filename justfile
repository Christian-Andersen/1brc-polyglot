default:
    @just --list

make-data:
    #!/usr/bin/env bash
    mkdir -p ./data/
    echo "*" > ./data/.gitignore
    for ((i=10; i<=10**9; i*=10)); do
      with_commas=$(printf "%'d" "$i")
      filename_suffix="${with_commas//,/_}"
      echo "Generating $with_commas measurements..."
      java ./CreateMeasurementsFast.java $i
      mv "./measurements.txt" "./data/${filename_suffix}.txt"
    done
