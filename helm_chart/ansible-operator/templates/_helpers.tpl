{{/*
Expand the name of the chart.
*/}}
{{- define "ansible-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ansible-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ansible-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ansible-operator.labels" -}}
helm.sh/chart: {{ include "ansible-operator.chart" . }}
{{ include "ansible-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ansible-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ansible-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ansible-operator.serviceAccountName" -}}
{{- default (include "ansible-operator.fullname" .) .Values.serviceAccount.name }}
{{- end }}

{{/* 
Service Account Annotations
*/}}
{{- define "ansible-operator.serviceAccountAnnotations" -}}
{{- if or .Values.serviceAccount.annotations .Values.chartWideAnnotations }}
annotations:
  {{- if .Values.serviceAccount.annotations }}
  {{- .Values.serviceAccount.annotations | toYaml | nindent 2 }}
  {{- end }}
  {{- if .Values.chartWideAnnotations }}
  {{- .Values.chartWideAnnotations | toYaml | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Manager Container Args
*/}}
{{- define "ansible-operator.manager-args" -}}
- --health-probe-bind-address={{ .Values.healthProbeBindAddress }}
{{ if .Values.metrics.enabled -}}
- --metrics-bind-address=127.0.0.1:{{ .Values.metrics.port }}
{{- end }}
- --leader-elect
- --leader-election-id={{ include "ansible-operator.fullname" . }}
{{- if .Values.managerArgs -}}
{{ range .Values.managerArgs }}
- --{{ . }}
{{- end }}
{{- end }}
{{ end }}

