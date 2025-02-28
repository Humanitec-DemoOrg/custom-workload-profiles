{{- /*
  feature.pod
  Generates a PodTemplateSpec object without .spec.containers.

  Expects a dict containing properties of PodSpec, excluding "containers" and include "annotations" and "labels"
  Returns: a PodTemplateSpec object without .spec.containers in YAML format.
*/ -}}
{{- define "feature.pod" }}
  {{ $metadata := (dict
    "annotations" (dict)
    "labels" (dict)
  ) }}
  {{ $spec := dict }}
  {{- range $k, $v := . }}
    {{- if or (eq $k "annotations") (eq $k "labels") }}
      {{- $metadata := (mergeOverwrite $metadata (dict $k $v)) }}
    {{- else if eq $k "containers" }}
      {{- fail "pod feature does not allow \"containers\" to be set. Use the top level \"containers\" feature." }}
    {{- else }}
      {{- $spec := (mergeOverwrite $spec (dict $k $v)) }}
    {{- end }}
  {{- end }}
metadata: {{ $metadata | toRawJson }}
spec: {{ $spec | toRawJson }}
{{- end }}

{{- /*
  feature.legacy-pod
  Generates the input expected for the new .Values.pod feature from .Values

  Expects .Values as an input
  Returns: a dict containing a subset of properties of PodSpec, excluding "containers" but including "annotations" and "labels in YAML format.
*/ -}}
{{- define "feature.legacy-pod" }}
{{- template "outputYAMLObject" (pick . "annotations") }}
{{- template "outputYAMLObject" (pick . "labels") }}
{{- template "outputYAMLObject" (pick . "affinity") }}
{{- template "outputYAMLObject" (pick . "automountServiceAccountToken") }}
{{- template "outputYAMLObject" (pick . "hostAliases") }}
{{- template "outputYAMLObject" (pick . "hostIPC") }}
{{- template "outputYAMLObject" (pick . "hostNetwork") }}
{{- template "outputYAMLObject" (pick . "hostPID") }}
{{- template "outputYAMLObject" (pick . "hostname") }}
{{- template "outputYAMLObject" (pick . "imagePullSecrets") }}
{{- template "outputYAMLObject" (pick . "nodeName") }}
{{- template "outputYAMLObject" (pick . "nodeSelector") }}
{{- template "outputYAMLObject" (pick . "preemptionPolicy") }}
{{- template "outputYAMLObject" (pick . "priority") }}
{{- template "outputYAMLObject" (pick . "priorityClassName") }}
{{- template "outputYAMLObject" (pick . "readinessGates") }}
{{- template "outputYAMLObject" (pick . "overhead") }}
{{- template "outputYAMLObject" (pick . "restartPolicy") }}
{{- template "outputYAMLObject" (pick . "runtimeClassName") }}
{{- template "outputYAMLObject" (pick . "schedulerName") }}
{{- template "outputYAMLObject" (pick . "securityContext") }}
{{- template "outputYAMLObject" (pick . "serviceAccountName") }}
{{- template "outputYAMLObject" (pick . "setHostnameAsFQDN") }}
{{- template "outputYAMLObject" (pick . "shareProcessNamespace") }}
{{- template "outputYAMLObject" (pick . "subdomain") }}
{{- template "outputYAMLObject" (pick . "terminationGracePeriodSeconds") }}
{{- template "outputYAMLObject" (pick . "tolerations") }}
{{- template "outputYAMLObject" (pick . "topologySpreadConstraints") }}
{{- template "outputYAMLObject" (pick . "restartPolicy") }}
{{- end }}