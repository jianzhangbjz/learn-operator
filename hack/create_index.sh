#create directory
versions=$2
bundledir=nginx$1
mkdir ${bundledir}
cd ${bundledir}

catalogdir=catalog
mkdir ${catalogdir}

kindStr=Nginxolm$1
kind=nginxolm$1
#init
operator-sdk init --plugins=ansible --domain example.com
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "init failed"
    exit 1
fi

#create api
operator-sdk create api --group cache --version v1alpha1 --kind ${kindStr} --generate-role
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "create api failed"
    exit 1
fi


cp ../default_main.yml roles/${kind}/defaults/main.yml
cp ../task_main.yml roles/${kind}/tasks/main.yml

#build operator image
podman manifest create quay.io/openshifttest/nginxolm-operator-base:${kind}
podman build --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x  --manifest quay.io/openshifttest/nginxolm-operator-base:${kind}  .
podman manifest push quay.io/openshifttest/nginxolm-operator-base:${kind}


#make bundle
make bundle IMG=quay.io/openshifttest/nginxolm-operator-base:${kind}

#modify csv
sed 's/supported: false/supported: true/g' bundle/manifests/${bundledir}.clusterserviceversion.yaml > bundle/manifests/${bundledir}.clusterserviceversion.yaml.new
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "modify failed"
    exit 1
fi
mv bundle/manifests/${bundledir}.clusterserviceversion.yaml.new bundle/manifests/${bundledir}.clusterserviceversion.yaml

podman build . -f bundle.Dockerfile -t quay.io/openshifttest/nginxolm-operator-bundle:v0.0.1-${kind}
podman push quay.io/openshifttest/nginxolm-operator-bundle:v0.0.1-${kind}
mv bundle bundle.0.0.1

index_config=${catalogdir}/catalog-config.yaml
echo "Schema: olm.semver" > ${index_config}
echo "Candidate:" >> ${index_config}
echo "  Bundles:" >> ${index_config}
echo "  - Image: quay.io/openshifttest/nginxolm-operator-bundle:v0.0.1-${kind}" >> ${index_config}


versionList=(${versions//,/ })
echo ${versionList}
for version_index in ${versionList[@]}
do
    echo "create bundle ${version_index}"
    cp -r bundle.0.0.1 bundle
    sed "s/v0.0.1/v${version_index}/g" bundle/manifests/${bundledir}.clusterserviceversion.yaml > bundle/manifests/${bundledir}.clusterserviceversion.yaml.new
    mv bundle/manifests/${bundledir}.clusterserviceversion.yaml.new bundle/manifests/${bundledir}.clusterserviceversion.yaml
    sed "s/version: 0.0.1/version: ${version_index}/g" bundle/manifests/${bundledir}.clusterserviceversion.yaml > bundle/manifests/${bundledir}.clusterserviceversion.yaml.new
    mv bundle/manifests/${bundledir}.clusterserviceversion.yaml.new bundle/manifests/${bundledir}.clusterserviceversion.yaml
    podman build . -f bundle.Dockerfile -t quay.io/openshifttest/nginxolm-operator-bundle:v${version_index}-${kind}
    podman push quay.io/openshifttest/nginxolm-operator-bundle:v${version_index}-${kind}
    echo "  - Image: quay.io/openshifttest/nginxolm-operator-bundle:v${version_index}-${kind}" >> ${index_config}
    mv bundle bundle.${version_index}
done

cd ${catalogdir}
mkdir catalog
opm alpha render-template semver catalog-config.yaml -o yaml > catalog/index.yaml
opm validate catalog
opm generate dockerfile catalog -b registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.19 -i registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.19
podman manifest create quay.io/openshifttest/nginxolm-operator-index:${kind}
podman build --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x  --manifest quay.io/openshifttest/nginxolm-operator-index:${kind}  . -f catalog.Dockerfile
podman manifest push quay.io/openshifttest/nginxolm-operator-index:${kind}

