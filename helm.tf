resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx" 
  }
  depends_on = [ module.kubernetes ]
}

resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = "4.12.0" # Specify the desired version

  values = [file("${path.module}/kubernetes/helm/ingress-nginx/values.yaml")]
depends_on = [ kubernetes_namespace.ingress_nginx ]
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager" 
  }
  depends_on = [ module.kubernetes ]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.12.0" # Specify the desired version
  values = [file("${path.module}/kubernetes/helm/cert-manager/values.yaml")]
  depends_on = [ kubernetes_namespace.cert_manager ]
}