aws_region         = "ca-west-1"
azs        = ["ca-west-1a", "ca-west-1b"]
project_name       = "portfolio-app"
admin_cidr         = "0.0.0.0/32"        # get it from https://whatismyip.com
key_name           = "portfolio-key"      # must already exist in your AWS account
db_password        = "password"       # use a real secret manager in production
asset_bucket_name  = "portfolio-app-assets-3tier"  # must be globally unique
