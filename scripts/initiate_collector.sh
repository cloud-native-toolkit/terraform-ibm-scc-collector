#!/bin/bash
controller="https://private.asap.compliance.cloud.ibm.com"
repourl="private.icr.io/posture-management/compliance-collector"
tag="0.0.1"
watch_tower="private.icr.io/posture-management/compliance-watchtower:0.0.1"
export IBM_REPO_URL=${repourl}
export IBM_TAG=${tag}
export IBM_WATCH_TOWER_IMAGE=${watch_tower}
export controller=${controller}
