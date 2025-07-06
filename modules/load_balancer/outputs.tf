output "loadbalancer_arn" {
  value = aws_lb.internal.arn
}

output "loadbalancer_id" {
  value = aws_lb.internal.id
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  value = try(aws_lb_listener.https.arn, null)
}
