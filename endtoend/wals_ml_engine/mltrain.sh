#!/usr/bin/env bash

usage () {
  echo "usage: mltrain.sh [local | train | tune] [gs://]<input_file>.csv
                  [--data-type ratings|web_views]
                  [--delimiter <delim>]
                  [--use-optimized]
                  [--headers]

Use 'local' to train locally with a local data file, and 'train' and 'tune' to
run on ML Engine.  For ML Engine jobs the input file must reside on GCS.

Optional args:
  --data-type:      Default to 'ratings', meaning MovieLens ratings from 0-5.
                    Set to 'web_views' for Google Analytics data.
  --delimiter:      CSV delimiter, default to '\t'.
  --use-optimized:  Use optimized hyperparamters, default False.
  --headers:        Default False for 'ratings', True for 'web_views'.

Examples:

# train locally with unoptimized hyperparams
./mltrain.sh local ../data/recommendation_events.csv --data-type web_views

# train on ML Engine with optimized hyperparams
./mltrain.sh train gs://rec_serve/data/recommendation_events.csv --data-type web_views --use-optimized

# tune hyperparams on ML Engine:
./mltrain.sh tune gs://rec_serve/data/recommendation_events.csv --data-type web_views
"

}

date

TIME=`date +"%Y%m%d_%H%M%S"`

# CHANGE TO YOUR BUCKET
BUCKET="gs://recserve_mlongcp"

if [[ $# < 2 ]]; then
  usage
  exit 1
fi

# set job vars
TRAIN_JOB="$1"
TRAIN_FILE="$2"
JOB_NAME=wals_ml_${TRAIN_JOB}_${TIME}
REGION=us-central1

# add additional args
shift; shift
ARGS="--train-files ${TRAIN_FILE} --verbose-logging $@"

if [[ ${TRAIN_JOB} == "local" ]]; then

  mkdir -p jobs/${JOB_NAME}

  gcloud ai-platform local train \
    --module-name trainer.task \
    --package-path trainer \
    -- \
    --job-dir jobs/${JOB_NAME} \
    ${ARGS}

elif [[ ${TRAIN_JOB} == "train" ]]; then

  gcloud ai-platform jobs submit training ${JOB_NAME} \
    --region $REGION \
    --scale-tier=CUSTOM \
    --job-dir ${BUCKET}/jobs/${JOB_NAME} \
    --module-name trainer.task \
    --package-path trainer \
    --config trainer/config/config_train.json \
    -- \
    ${ARGS}

elif [[ $TRAIN_JOB == "tune" ]]; then

  # set configuration for tuning
  CONFIG_TUNE="trainer/config/config_tune.json"
  for i in $ARGS ; do
    if [[ "$i" == "web_views" ]]; then
      CONFIG_TUNE="trainer/config/config_tune_web.json"
      break
    fi
  done

  gcloud ai-platform jobs submit training ${JOB_NAME} \
    --region ${REGION} \
    --scale-tier=CUSTOM \
    --job-dir ${BUCKET}/jobs/${JOB_NAME} \
    --module-name trainer.task \
    --package-path trainer \
    --config ${CONFIG_TUNE} \
    -- \
    --hypertune \
    ${ARGS}

else
  usage
fi

date
