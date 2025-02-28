
{{- /*
  feature.container.probe
  Generates a Kubernetes Probe from the humanitec/containers-probe feature

  Expects a dict representing either the humanitec/containers-probe feature
  Returns: a YAML Kubernetes Probe object.
*/ -}}
{{- define "feature.container.probe" }}
  {{- if eq .type "http" }}
httpGet:
  path: {{ .path | quote }}
    {{- /*
      Do not quote the port as it should be an integer if a port number
      or a string if it is a port name.
      Legacy code has port numbers as strings, so by not quoting legacy code
      is preserved.
    */ -}}
    {{- if .port }}
  port: {{ .port }}
    {{- end }}
    {{- if .scheme }}
  scheme: {{ .scheme }}
    {{- end }}
    {{- if .headers }}
  httpHeaders:
      {{- range $name, $val := .headers }}
  - name: {{ $name | quote }}
    value: {{ $val | quote }}
      {{- end }}
    {{- end }}
    {{- end }}
    {{- if eq .type "tcp" }}
tcpSocket:
  port: {{ .port }}
    {{- end }}
    {{- if eq .type "grpc" }}
grpc:
  port: {{ .port }}
    {{- if .service }}
  service: {{ .service }}
    {{- end }}
  {{- end }}
  {{- if eq .type "command" }}
exec:
  command:
    {{- range .command }}
  - {{ . | quote }}
    {{- end }}
  {{- end }}
  {{- template "outputYAMLObject" (pick . "initialDelaySeconds") }}
  {{- template "outputYAMLObject" (pick . "periodSeconds") }}
  {{- template "outputYAMLObject" (pick . "timeoutSeconds") }}
  {{- template "outputYAMLObject" (pick . "successThreshold") }}
  {{- template "outputYAMLObject" (pick . "failureThreshold") }}
{{- end }}

{{- /*
  feature.container.lifecycleHandler
  Generates a Kubernetes LifecycleHandler
  It supports both the legacy Humanitec definition in the following schema:
    type: "http"|"tcp"|"command"
    ...
  And the standard Kubernetes object

  Expects a dict representing either the Humanietc LifecycleHandler or Kubernetes LifecycleHandler
  Returns: a YAML Kubernetes LifecycleHandler object.
*/ -}}
{{- define "feature.container.lifecycleHandler" }}
  {{- if hasKey . "type" }}
    {{- if eq .type "http" }}
httpGet:
  path: {{ .path }}
      {{- if .host }}
  host: {{ .host }}
      {{- end }}
      {{- /*
        Do not quote the port as it should be an integer if a port number
        or a string if it is a port name.
        Legacy code has port numbers as strings, so by not quoting legacy code
        is preserved.
      */ -}}
      {{- if .port }}
  port: {{ .port }}
      {{- end }}
      {{- if .scheme }}
  scheme: {{ .scheme }}
      {{- end }}
      {{- if .headers }}
  httpHeaders:
      {{- range $name, $val := .headers }}
  - name: {{ $name }}
    value: {{ $val }}
      {{- end }}
      {{- end }}
    {{- end }}
    {{- if eq .type "tcp" }}
tcpSocket:
  port: {{ .port }}
      {{- if .host }}
  host: {{ .host }}
      {{- end }}
    {{- end }}
    {{- if eq .type "command" }}
exec:
  command:
      {{- range .command }}
  - {{ . | quote }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}


{{- /*
  feature.containers
  Generates a list of Kubernetes Container objects in YAML format.

  Expects a dict with 3 parameters: "containers", "defaults" and "resPrefix"
  "containers" (map)    content of .Values.containers
  "defaults"   (map)    an object that will be applied to each container if those properties don't exist
  "resPrefix"  (string) the prefix for the configMap used for environment variables
  Returns: a YAML array of Kubernetes Container objects.
*/ -}}
{{- define "feature.containers" }}
  {{- range $id, $container := .containers }}

  {{- /*
    This is a shallow defaults.
  */ -}}
  {{- range $k, $v := $.defaults }}
    {{- if not (hasKey $container $k) }}
      {{- $_ := set $container $k $v }}
    {{- end }}
  {{- end }}

- {{ (dict "name" $id "resPrefix" $.resPrefix "container" $container) | include "feature.container" | fromYaml | toRawJson }}
  {{- end }}
{{- end }}

{{- /*
  feature.container
  Generates a Kubernetes Container in YAML format.

  Expects a dict with 3 parameters: "container", "id" and "resPrefix"
  "container" (map)    content of .Values.containers.<id>
  "name"      (string) the name of the container
  "resPrefix" (string) the prefix for the configMap used for environment variables
  Returns: a YAML object
*/ -}}
{{- define "feature.container" }}
  {{- with .container }}

    {{- /*
      These properties are part of the humanitec/container Workload Profile Feature
    */ -}}
name: {{ $.name }}
image: {{ .image | toRawJson }}
    {{- if "liveness_probe" | hasKey . }}
livenessProbe: {{ include "feature.container.probe" .liveness_probe | fromYaml | toRawJson }}
    {{- end }}
    {{- if "readiness_probe" | hasKey . }}
readinessProbe: {{ include "feature.container.probe" .readiness_probe | fromYaml | toRawJson }}
    {{- end }}
    {{- if "startup_probe" | hasKey . }}
startupProbe: {{ include "feature.container.probe" .startup_probe | fromYaml | toRawJson }}
    {{- end }}
    {{- template "outputYAMLObject" (pick . "resources") }}
    {{- template "outputYAMLObject" (pick . "command") }}
    {{- template "outputYAMLObject" (pick . "args") }}

    {{- /*
      These properties are not part of the Workload Profile Feature, but are part of how
      values, secrets and volumes are handled.
    */ -}}
    {{- template "outputYAMLObject" (pick . "env") }}
envFrom:
- configMapRef:
    name: {{ $.resPrefix }}-configmap-{{ $.name }}

{{- range $envFromSource := .envFrom | default (list) }}
- {{ $envFromSource | toRawJson }}
{{- end }}

    {{- if or .volumeMounts .volume_mounts }}
volumeMounts:
      {{- if "volumeMounts" | hasKey . }}
        {{- .volumeMounts | toYaml | nindent 0}}
      {{- end }}
      {{- if "volume_mounts" | hasKey . }}
        {{- range $path, $data := .volume_mounts }}
- name: {{ $data.id | quote }}
  mountPath: {{ $path | quote }}
          {{- if $data.sub_path }}
  subPath: {{ $data.sub_path | quote }}
          {{- end }}
          {{- if $data.read_only }}
  readOnly: {{ $data.read_only }}
          {{- end }}
       {{- end }}
      {{- end }}
    {{- end }}

    {{- /*
      These properties are part of the Kubernetes Container object and not in the Workload Profile Feature.
      They are "passed through" to the Kubernetes object
    */ -}}
    {{- template "outputYAMLObject" (pick . "imagePullPolicy") }}
    {{- if "lifecycle" | hasKey . }}
lifecycle:
      {{- if "preStop" | hasKey .lifecycle }}
  preStop: {{ include "feature.container.lifecycleHandler" .lifecycle.preStop | fromYaml | toRawJson  }}
      {{- end }}
      {{- if "postStart" | hasKey .lifecycle }}
  postStart: {{ include "feature.container.lifecycleHandler" .lifecycle.postStart | fromYaml | toRawJson }}
      {{- end }}
    {{- end}}
    {{- template "outputYAMLObject" (pick . "securityContext") }}
    {{- template "outputYAMLObject" (pick . "stdin") }}
    {{- template "outputYAMLObject" (pick . "stdinOnce") }}
    {{- template "outputYAMLObject" (pick . "terminationMessagePath") }}
    {{- template "outputYAMLObject" (pick . "terminationMessagePolicy") }}
    {{- template "outputYAMLObject" (pick . "tty") }}
    {{- template "outputYAMLObject" (pick . "volumeDevices") }}
    {{- template "outputYAMLObject" (pick . "workingDir") }}
  {{- end}}
{{- end }}