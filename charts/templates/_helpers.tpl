{{/* Operator Deployment name. The console looks it up as KEENPGO_OPERATOR_NAME. */}}
{{- define "keenpg-operator.fullname" -}}
{{- default "keenpgo" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "keenpg-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default "pgo" .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "keenpg-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Labels shared by everything in the chart. */}}
{{- define "keenpg-operator.commonLabels" -}}
helm.sh/chart: {{ include "keenpg-operator.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: keenpg
{{- end -}}

{{- define "keenpg-operator.operatorLabels" -}}
{{ include "keenpg-operator.commonLabels" . }}
app.kubernetes.io/name: keenpgo
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
keenpg.io/control-plane: keenpg-operator
{{- end -}}

{{/* Deployment selector: same label the kustomize install uses (immutable). */}}
{{- define "keenpg-operator.operatorSelectorLabels" -}}
keenpg.io/control-plane: keenpg-operator
{{- end -}}

{{- define "keenpg-operator.consoleLabels" -}}
{{ include "keenpg-operator.commonLabels" . }}
app.kubernetes.io/name: keenpgo-console
{{- end -}}

{{- define "keenpg-operator.consoleSelectorLabels" -}}
app.kubernetes.io/name: keenpgo-console
{{- end -}}

{{- define "keenpg-operator.consoleDbLabels" -}}
{{ include "keenpg-operator.commonLabels" . }}
app.kubernetes.io/name: keenpgo-console-db
{{- end -}}

{{- define "keenpg-operator.consoleDbSelectorLabels" -}}
app.kubernetes.io/name: keenpgo-console-db
{{- end -}}

{{/* imagePullSecrets block (pod level and ServiceAccount level). */}}
{{/* Effective pull Secret name ("" = none). */}}
{{- define "keenpg-operator.pullSecretName" -}}
{{- if .Values.pullSecret.create -}}
{{- default "keenpg-pull" .Values.pullSecret.name -}}
{{- else -}}
{{- .Values.pullSecret.name -}}
{{- end -}}
{{- end -}}

{{- define "keenpg-operator.imagePullSecrets" -}}
{{- $name := include "keenpg-operator.pullSecretName" . -}}
{{- if $name -}}
imagePullSecrets:
  - name: {{ $name }}
{{- end -}}
{{- end -}}

{{/* Name of the console admin Secret. */}}
{{- define "keenpg-operator.consoleAdminSecret" -}}
{{- default "keenpgo-console-admin" .Values.console.admin.existingSecret -}}
{{- end -}}

{{/* Name of the console DB password Secret (fixed: the console finds it by name). */}}
{{- define "keenpg-operator.consoleDbSecret" -}}
{{- default "keenpgo-console-db" .Values.console.db.existingSecret -}}
{{- end -}}

{{/* Operator rules. Shared by the ClusterRole and the namespaced Role. */}}
{{- define "keenpg-operator.operatorRules" -}}
- apiGroups: [""]
  resources: [configmaps, persistentvolumeclaims, secrets, serviceaccounts, services]
  verbs: [create, delete, get, list, patch, watch]
- apiGroups: [""]
  resources: [endpoints]
  verbs: [create, delete, deletecollection, get, list, patch, watch]
- apiGroups: [""]
  resources: [endpoints/restricted, pods/exec]
  verbs: [create]
- apiGroups: [""]
  resources: [events]
  verbs: [create, patch]
- apiGroups: [""]
  resources: [pods]
  verbs: [delete, get, list, patch, watch]
- apiGroups: [apps]
  resources: [deployments, statefulsets]
  verbs: [create, delete, get, list, patch, watch]
- apiGroups: [authentication.k8s.io]
  resources: [tokenreviews]
  verbs: [create]
- apiGroups: [authorization.k8s.io]
  resources: [subjectaccessreviews]
  verbs: [create]
- apiGroups: [batch]
  resources: [cronjobs, jobs]
  verbs: [create, delete, get, list, patch, watch]
- apiGroups: [coordination.k8s.io]
  resources: [leases]
  verbs: [create, get, update, watch]
- apiGroups: [keenpg.io]
  resources: [keenpgclusters]
  verbs: [get, list, patch, watch]
- apiGroups: [keenpg.io]
  resources: [keenpgclusters/finalizers, pgadmins/finalizers, pgupgrades/finalizers]
  verbs: [update]
- apiGroups: [keenpg.io]
  resources: [keenpgclusters/status, pgadmins/status, pgupgrades/status]
  verbs: [patch]
- apiGroups: [keenpg.io]
  resources: [pgadmins, pgupgrades]
  verbs: [get, list, watch]
- apiGroups: [policy]
  resources: [poddisruptionbudgets]
  verbs: [create, delete, get, list, patch, watch]
- apiGroups: [rbac.authorization.k8s.io]
  resources: [rolebindings, roles]
  verbs: [create, delete, get, list, patch, watch]
- apiGroups: [snapshot.storage.k8s.io]
  resources: [volumesnapshots]
  verbs: [create, delete, get, list, patch, watch]
{{- end -}}
