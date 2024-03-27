# Copyright 2019 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# syntax=docker/dockerfile:1

################################################################################
##                               BUILD ARGS                                   ##
################################################################################
# This build arg allows the specification of a custom Golang image.
ARG GOLANG_IMAGE=golang:1.22

# Base docker image (like distroless)
ARG BASE_IMAGE

FROM ${GOLANG_IMAGE} AS builder

ARG ENABLE_GIT_COMMAND=true
ARG TARGETOS
ARG TARGETARCH
ARG VERSION

WORKDIR /go/src/sigs.k8s.io/cloud-provider-azure
COPY go.mod go.sum ./
COPY cmd/ cmd/
COPY pkg/ pkg/
COPY vendor/ vendor/

RUN GO111MODULE=on CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -trimpath \
    -ldflags="-w -s -X k8s.io/component-base/version.gitVersion=$VERSION" \
    -o=azure-cloud-controller-manager \
    ./cmd/cloud-controller-manager

FROM ${BASE_IMAGE}
COPY --from=builder /go/src/sigs.k8s.io/cloud-provider-azure/azure-cloud-controller-manager /bin/azure-cloud-controller-manager
ENTRYPOINT [ "/bin/azure-cloud-controller-manager" ]
