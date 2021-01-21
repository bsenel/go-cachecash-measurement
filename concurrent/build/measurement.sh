#!/bin/bash
exec &> ./measurement-log.txt

FILE=$1
INTERVAL=$2
CLIENTLIMIT=$3
z=0
while :
do
  z=$((z+1))
  echo "Welcome to $z. run"
  counter=0
  NODELIST=$(kubectl get node --template '{{range .items}}{{.metadata.name}}{{" "}}{{end}}')
  declare -a arr=(${NODELIST})
  for i in "${arr[@]}"
  do
    counter=$((counter+1))
    echo "$i"
    READY=$(kubectl get nodes "$i" -o wide | grep "NotReady")

    if [ "$counter" -lt "$CLIENTLIMIT" ]
    then
      if [ "$READY" = "" ]
      then
        printf "Current date and time: %s\n" "$(date +'%m-%d-%Y %H:%M:%S')"
        if [ "$FILE" = "" ]
        then
           kubectl -n authority-edgenet-slice-cachecash run cachecash-curl-"$z-$i" --overrides='{ "apiVersion": "v1", "spec": { "nodeName": "'$i'", "containers": [ { "args": [ "/bin/sh", "-c", "./cachecash-curl -o output.mp4 -logLevel=debug -trace http://cachecash-collector:14268 cachecash://cachecash.planet-lab.eu:30070/frag_bunny.mp4" ], "image": "bsenel/cachecash-curl:latest", "imagePullPolicy": "IfNotPresent", "name": "cachecash-curl", "resources": {}, "stdin": true, "stdinOnce": true, "terminationMessagePath": "/dev/termination-log", "terminationMessagePolicy": "File", "tty": true, "volumeMounts": [ { "mountPath": "/tls", "name": "tls" } ] } ], "volumes": [ { "csi": { "driver": "csi.cert-manager.io", "volumeAttributes": { "csi.cert-manager.io/certificate-file": "server-cert.pem", "csi.cert-manager.io/common-name": "cachecash-curl", "csi.cert-manager.io/dns-names": "cachecash-curl", "csi.cert-manager.io/issuer-name": "ca-issuer-cachecash", "csi.cert-manager.io/privatekey-file": "server-key.pem" } }, "name": "tls" } ] } }' --pod-running-timeout=20s -it --image=bsenel/cachecash-curl --restart=Never --rm &
        else
           kubectl -n authority-edgenet-slice-cachecash run cachecash-curl-"$z-$i" --overrides='{ "apiVersion": "v1", "spec": { "nodeName": "'$i'", "containers": [ { "args": [ "/bin/sh", "-c", "./cachecash-curl -o '$FILE' -logLevel=debug -trace http://cachecash-collector:14268 cachecash://cachecash.planet-lab.eu:30070/'$FILE'" ], "image": "bsenel/cachecash-curl:latest", "imagePullPolicy": "IfNotPresent", "name": "cachecash-curl", "resources": {}, "stdin": true, "stdinOnce": true, "terminationMessagePath": "/dev/termination-log", "terminationMessagePolicy": "File", "tty": true, "volumeMounts": [ { "mountPath": "/tls", "name": "tls" } ] } ], "volumes": [ { "csi": { "driver": "csi.cert-manager.io", "volumeAttributes": { "csi.cert-manager.io/certificate-file": "server-cert.pem", "csi.cert-manager.io/common-name": "cachecash-curl", "csi.cert-manager.io/dns-names": "cachecash-curl", "csi.cert-manager.io/issuer-name": "ca-issuer-cachecash", "csi.cert-manager.io/privatekey-file": "server-key.pem" } }, "name": "tls" } ] } }' --pod-running-timeout=20s -it --image=bsenel/cachecash-curl --restart=Never --rm &
        fi
       else
         echo "NotReady"
       fi
    else
      echo "Client Limit Exceeded: $i"
    fi
  done
  sleep $INTERVAL
done
