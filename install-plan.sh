#!/bin/bash

# Make this a dependant chart and source the namespace ($SUBS) from the child chart
# Its a single one off job on deploy
# If its a cron job it will auto approve till its at latest
# If its down rev the argo app will lways be syncing..
# the app will go degraded if git is not changed to match the upgraded version


SUBS="openshift-compliance openshift-gitops-operator"

for i in $SUBS
  do

    IP=$(oc get sub -n $i -o jsonpath='{.items[0].status.installplan.name}')

    if [ $(oc get installplan $IP -n $i -o jsonpath='{.spec.approved}') == false ]

    then
      echo "Approving $i operator install -- $IP"
      oc patch installplan $IP -n $i --type='merge' -p '{"spec": {"approved": true}}'
      echo ""


    fi


done
