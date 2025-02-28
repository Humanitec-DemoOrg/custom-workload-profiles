{{- /*
  Utility template to output a YAML object.
  Useful for only outputting keys that exist in the input when combined with pick.
  For example:
  {{- template "outputYAMLObject" (pick $someMap "output-if-exists") }}
*/ -}}
{{- define "outputYAMLObject" }}
{{- range $k, $v := . }}
{{ $k | nindent 0 }}: {{ $v | toRawJson }}
{{- end }}
{{- end }}