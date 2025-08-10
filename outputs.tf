output "private_subnets" {
   value =  module.networking.private_subnets
}

output "cluster_name" {
   value =  module.eks.cluster_name
}