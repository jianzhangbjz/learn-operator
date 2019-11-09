# learn-operator
This is an sample operator created by using the operator-sdk

There is a new resource called `learn`. When you use this resource, you should special the `size`.

### Deploy it on the Kubernetes or OpenShift
```console
$ oc create -f deploy/role.yaml 
role.rbac.authorization.k8s.io/learn-operator created
$ oc create -f deploy/role_binding.yaml 
rolebinding.rbac.authorization.k8s.io/learn-operator created
$ oc create -f deploy/operator.yaml 
deployment.apps/learn-operator created
$ oc create -f deploy/crds/app.learn.com_learns_crd.yaml 
customresourcedefinition.apiextensions.k8s.io/learns.app.learn.com created
```

### Create CR
```console
$ cat deploy/crds/app.learn.com_v1_learn_cr.yaml 
apiVersion: app.learn.com/v1
kind: Learn
metadata:
  name: example-learn
spec:
  # Add fields here
  size: 2
```
### Check the lean instance
```console
$ oc create -f  deploy/crds/app.learn.com_v1_learn_cr.yaml 
learn.app.learn.com/example-learn created
$ oc get learn
NAME            AGE
example-learn   14s
mac:learn-operator jianzhang$ oc get pods
NAME                              READY   STATUS    RESTARTS   AGE
example-learn-6764b9858-45rc2     1/1     Running   0          25s
example-learn-6764b9858-xq6mf     1/1     Running   0          25s
learn-operator-768d88c6d6-t6w5h   1/1     Running   0          113s
```
