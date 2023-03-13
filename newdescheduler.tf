resource "aws_eks_cluster" "my_cluster" {
  name = "my-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  vpc_config {
    subnet_ids = aws_subnet.private.*.id
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.eks_service_role,
  ]
}

resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_service_role" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "kubernetes_config_map" "descheduler" {
  metadata {
    name = "descheduler"
    namespace = "kube-system"
  }

  data = {
    policy-config = <<-EOF
    apiVersion: descheduler/v1alpha1
    kind: DeschedulerPolicy
    strategies:
      - name: RemoveDuplicates
      - name: RemovePodsViolatingInterPodAntiAffinity
        enabled: true
        args:
        - removePodsViolatingInterPodAntiAffinity,--label-selector=app=my-app
        - removePodsViolatingInterPodAntiAffinity,--label-selector=app=my-app2
      - name: RemovePodsViolatingNodeAffinity
        enabled: true
        args:
        - removePodsViolatingNodeAffinity,--label-selector=app=my-app
        - removePodsViolatingNodeAffinity,--label-selector=app=my-app2
      - name: RemovePodsViolatingTopologySpreadConstraint
        enabled: true
        args:
        - removePodsViolatingTopologySpreadConstraint,--label-selector=app=my-app
        - removePodsViolatingTopologySpreadConstraint,--label-selector=app=my-app2
      - name: RemovePodsViolatingResourceLimits
    EOF
  }
}

resource "kubernetes_deployment" "descheduler" {
  metadata {
    name = "descheduler"
    namespace = "kube-system"
    labels = {
      app = "descheduler"
    }
  }

  spec {
    replicas = 1

    selector {
      matchLabels = {
        app = "descheduler"
      }
    }

    template {
      metadata {
        labels = {
          app = "descheduler"
        }
      }

      spec {
        container {
          image = "k8s.gcr.io/descheduler/descheduler:v0.22.0"
          name = "descheduler"
          command = [
            "/usr/local/bin/descheduler",
            "--policy-configmap",
            "descheduler",
          ]
