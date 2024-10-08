{{- define "ingress.ingress_single" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.name }}
  labels:
    businessid: {{ .Values.businessid | quote }}
    {{- range $key, $value := .Values.ingress.labels }}
    {{ $key }}: {{ $value }}
    {{- end }}
  annotations:
    {{- $omittedAnnotations := omit .Values.ingress.annotations "alb.ingress.kubernetes.io/tags" }}
{{ toYaml $omittedAnnotations | indent 4 }}    
    {{- if and (not (index .Values.ingress.annotations "alb.ingress.kubernetes.io/ssl-policy")) (index .Values.ingress.annotations "alb.ingress.kubernetes.io/load-balancer-name") (index .Values.ingress.annotations "alb.ingress.kubernetes.io/certificate-arn") }}
    alb.ingress.kubernetes.io/ssl-policy: "ELBSecurityPolicy-TLS13-1-2-2021-06"
    {{- end }}
    {{- if eq (index .Values.ingress.annotations "kubernetes.io/ingress.class") "alb" }}
    {{- if not (index .Values.ingress.annotations "alb.ingress.kubernetes.io/tags") }}
    alb.ingress.kubernetes.io/tags: {{ printf "businessid=%s" .Values.businessid | quote }}
    {{- else }}
    {{- $tags := index .Values.ingress.annotations "alb.ingress.kubernetes.io/tags" }}
    {{- if not (regexMatch "businessid=[^,]+" $tags) }}
    {{- $newTags := printf "%s,businessid=%s" $tags .Values.businessid | quote }}
    alb.ingress.kubernetes.io/tags: {{ $newTags }}
    {{- else }}
    alb.ingress.kubernetes.io/tags: {{ $tags }}
    {{- end }}  
    {{- end }}
    {{- end }}
spec:
  {{- if .Values.ingress.tls }}
  tls:
    - hosts:
    {{- range .Values.ingress.tls.hosts }}
        - "{{ .host }}"
    {{- end }}
      secretName: {{ .Values.ingress.tls.secretName }}
  {{- end }}
  rules:
    {{- range .Values.ingress.rules }}
    -
      {{- if .host}}
      host: "{{ .host }}"
      {{- end }}
      http:
        paths:
        {{- range .http.paths }}
        - backend:
            service:
              name: {{ .backend.serviceName }}
              port: 
              {{- if regexMatch "^[1-9][0-9]+$" (toString .backend.servicePort) }}
                number: {{ .backend.servicePort }}
              {{- else }}
                name: {{ .backend.servicePort }}
              {{- end }}
          path: {{ .path | default "/*" }}
          pathType: {{ .pathType | default "ImplementationSpecific" }}
        {{- end }}
    {{- end }}
{{- end -}}