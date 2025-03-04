{{- /*
  k8s.podTemplateSpec
  Generates a Kubernetes PodTemplateSpec object for use in controllers such as Deployment, Job and CronJob

  This is intended to be reusable across default-module, default-job and default-cronjob

  Expects the root of the Chart to be passed in.
  Returns: a YAML object of a PodTemplateSpec
*/ -}}
{{- define "k8s.podTemplateSpec" }}
  {{- /*
    $pod contains a PodTemplateSpec including "metadata" and "spec" fields at the top level.
    $pod.spec does not container "containers" or "volumes"
  */ -}}
  {{-
      $pod := mergeOverwrite (.Values | include "feature.legacy-pod" | fromYaml) (default (dict) .Values.pod) | 
      include "feature.pod" | fromYaml
  }}
  {{- 
      $_ := set $pod.metadata "labels"  (mergeOverwrite $pod.metadata.labels (include "helpers.selectorLabels" . | fromYaml)) 
  }}
  {{-
      $_ := set $pod.metadata.annotations "checksum/config" ( include (print $.Template.BasePath "/configmap.yaml") . | sha256sum )
  }}

  {{- /*
      $containers contains an array of Container objects.
      According to the spec, there *must* be at least 1 container, so the array will have at least 1 entry
  */ -}}
  {{-
      $containers := (dict
      "containers" .Values.containers
      "defaults"   (dict "resources" .Values.default_container_resources)
      "resPrefix"   .Release.Name
      ) | include "feature.containers" | fromYamlArray
  }}
  {{-
      $containers = concat $containers (default (list) .Values.extraContainers)
  }}

  {{- /*
      $volumes contains an array of Volume objects.
      This array *can* be zero.
  */ -}}
  {{-
      $volumes := (dict
      "resPrefix" .Release.Name
      "volumes"  (default (dict) .Values.volumes) 
      ) | include "feature.volumes" | fromYamlArray
  }}
  {{-
      $volumes = concat $volumes (default (list) .Values.extraVolumes)
  }}

  {{- $_ := set $pod.spec "containers" $containers }}
  {{- if and $volumes (gt (len $volumes) 0 ) }}
      {{- $_ = set $pod.spec "volumes" $volumes }}
  {{- end }}

  {{- /*
    Handle the edge case described here: https://github.com/kubernetes/kubernetes/issues/72519#issuecomment-451292986
      serviceAccountName is defaulted from serviceAccount for backwards compatibility. If you want to remove the fields
      you must set both to empty explicitly. It is not possible to leave one field unset.

    This is also documented in the official docs here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#use-multiple-service-accounts
      The .spec.serviceAccount field is a deprecated alias for .spec.serviceAccountName. If you want to remove the
      fields from a workload resource, set both fields to empty explicitly on the pod template.
  */ -}}
  {{- if hasKey $pod.spec "serviceAccountName" }}
    {{- $_ := set $pod.spec "serviceAccount" $pod.spec.serviceAccountName }}
  {{- else }}
    {{- $_ := set $pod.spec "serviceAccount" "" }}
    {{- $_ := set $pod.spec "serviceAccountName" "" }}
  {{- end }}

  {{- /*
      This is where the PodTemplateSpec is actually generated.
  */ -}}
  {{- $pod | toYaml }}
{{- end }}