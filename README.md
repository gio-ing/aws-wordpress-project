# aws-wordpress-project
Architecture for a wordpress application in AWS

Requirements
Name	Version
terraform	>= 1.0
aws	>= 5.82
null	>= 2.0
random	>= 3.6
Providers
Name	Version
aws	>= 5.82
null	>= 2.0
random	>= 3.6
Modules
Name	Source	Version
acm	terraform-aws-modules/acm/aws	~> 4.0
alb	../../	n/a
alb_disabled	../../	n/a
lambda_with_allowed_triggers	terraform-aws-modules/lambda/aws	~> 6.0
lambda_without_allowed_triggers	terraform-aws-modules/lambda/aws	~> 6.0
log_bucket	terraform-aws-modules/s3-bucket/aws	~> 3.0
vpc	terraform-aws-modules/vpc/aws	~> 5.0
wildcard_cert	terraform-aws-modules/acm/aws	~> 4.0
