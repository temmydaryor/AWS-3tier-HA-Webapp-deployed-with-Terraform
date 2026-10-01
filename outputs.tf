output "alb_dns_name" {
  description = "Paste this into your browser to test the app"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "CDN endpoint for static assets"
  value       = module.cdn.cloudfront_domain_name
}

output "rds_endpoint" {
  description = "Database endpoint (private, app tier only)"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
