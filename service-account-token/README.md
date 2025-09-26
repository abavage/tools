## serviceAccount & secret
Add config to enable login via serviceAccount token  

```
oc get secret bob-serviceaccount-secret -o json | jq -r '.data.token' | base64 -d

oc login https://api.one.xzxj.p3.openshiftapps.com:443 --token='<token>'

```

