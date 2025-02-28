{{- /*
  feature.volumes
  Generates a possibly empty list of Kubernetes Volume objects.

  Expects a dict with 2 parameters:  "resPrefix" and "volumes"
  "resPrefix" (string) the prefix for the ConfigMap / Secret used for projected files
  "volumes"   (dict)   content of .Values.volumes
  Returns: a possibly empty YAML list of Kubernetes Volume objects.
*/ -}}
{{- define "feature.volumes" }}
  {{- if eq (len .volumes) 0 }}
[]
  {{- else }}
    {{- range $name, $data := .volumes }}
- name: {{ $name }}
      {{- if eq $data.type "emptyDir" }}
        {{- if $data.source }}
  emptyDir: {{ toRawJson $data.source }}
        {{- else }}
  emptyDir: {}
        {{- end }}
      {{- end }}
      {{- if eq $data.type "projected" }}
  projected:
    sources:
        {{- if and $data.secret $data.secret.items }}
    - secret:
        name: {{ $.resPrefix }}-secrets
        items: {{ $data.secret.items | toRawJson }}
        {{- end }}
        {{- if and $data.configMap $data.configMap.items }}
    - configMap:
        name: {{ $.resPrefix }}-configmap
        items: {{ $data.configMap.items | toRawJson }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end}}
{{- end }}