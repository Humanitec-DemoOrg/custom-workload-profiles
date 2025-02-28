{{/* vim: set filetype=mustache: */}}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "helper.chart" }}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/* Common labels */}}
{{- define "helpers.defaultLabels" }}
helm.sh/chart: {{ include "helper.chart" . }}
{{ include "helpers.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- end }}

{{/* Selector labels */}}
{{- define "helpers.selectorLabels" }}
app.kubernetes.io/name: {{ .Release.Name | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end }}
