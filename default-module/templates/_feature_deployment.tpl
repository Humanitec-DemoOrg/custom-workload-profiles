{{- /*
  feature.deployment
  Generates a Kubernetes Deployment object with top level properties of "metadata" and "spec".

  Expects a dict containing properties of DeploymentSpec, excluding "paused", "selector" and "template",
    but including "annotations" and "labels"
  Returns: a YAML object of a Deployment with metadata and spec fields
           excluding .spec.paused, .spec.selector and .spec.template in YAML format.
*/ -}}
{{- define "feature.deployment" }}
  {{ $metadata := dict }}
  {{ $spec := dict }}
  {{- range $k, $v := . }}
    {{- if or (eq $k "annotations") (eq $k "labels") }}
      {{- $metadata := (mergeOverwrite $metadata (dict $k $v)) }}
    {{- else if or (eq $k "selector") (eq $k "template") }}
      {{- fail (printf "Workload Profile deployment feature does not allow \"%s\" to be set." $k) }}
    {{- else }}
      {{- $spec := (mergeOverwrite $spec (dict $k $v)) }}
    {{- end }}
  {{- end }}
metadata: {{ $metadata | toRawJson }}
spec: {{ $spec | toRawJson }}
{{- end }}

{{- /*
  feature.legacy-deployment
  Generates the input expected for the new .Values.deployment feature from .Values

  Expects .Values as an input
  Returns: a dict containing a subset of properties of DeploymentSpec,
           excluding "paused", "selector" and "template" in YAML format.
*/ -}}
{{- define "feature.legacy-deployment" }}
  {{- pick . "minReadySeconds" "progressDeadlineSeconds" "replicas" "strategy" | toRawJson }}
{{- end }}