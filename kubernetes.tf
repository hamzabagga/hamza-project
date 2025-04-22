resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = file("${path.root}/kubernetes/manifests/certificates/cluster-issuer.yaml")
  depends_on = [ helm_release.cert_manager ]
}
 
 resource "kubectl_manifest" "certificate_nginx" {
  yaml_body = file("${path.root}/kubernetes/manifests/certificates/certificate-nginx.yaml")
  depends_on = [ kubectl_manifest.cluster_issuer ]
 }

resource "kubectl_manifest" "ingress_nginx" {
  yaml_body = file("${path.root}/kubernetes/manifests/nginx-ingress.yaml")
  depends_on = [ kubectl_manifest.certificate_nginx ]
}