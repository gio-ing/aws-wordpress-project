module "s3_bucket_for_logs" {
  source    = "terraform-aws-modules/s3-bucket/aws"
  version   = "4.3.0"
  encrypted = true

  bucket = "${var.project}-${var.environment}-alb-logs"
  acl    = "log-delivery-write"

  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true
  attach_lb_log_delivery_policy  = true
}

module "s3_bucket_for_public_assets" {
  source    = "terraform-aws-modules/s3-bucket/aws"
  version   = "4.3.0"
  encrypted = true

  bucket        = "${var.project}-${var.environment}-public-assets"
  acl           = "public-read"
  force_destroy = true


}

resource "aws_efs_file_system" "wordpress_efs" {
  creation_token = "${var.project}-${var.environment}-efs"
  encrypted      = true

  tags = {
    Name = "${var.project}-${var.environment}-efs"
  }
}

resource "aws_efs_mount_target" "mountpoint" {
  file_system_id  = aws_efs_file_system.wordpress_efs.id
  subnet_id       = module.vpc.public_subnets
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  name   = "${var.project}-${var.environment}-efs-sg"
  vpc_id = module.vpc.vpc_id


  ingress {

    from_port       = "2049"
    to_port         = "2049"
    protocol        = "nfs"
    security_groups = [aws_security_group.lt_sg.id]

  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.lt_sg.id]
  }

  tags = {
    "Name" = "efs_sg"
  }
}

module "db" {
  source                              = "terraform-aws-modules/rds/aws"
  version                             = "6.10.0"
  identifier                          = "${var.project}-${var.environment}-rds"
  engine                              = var.rds_engine
  engine_version                      = var.rds_engine_version
  instance_class                      = var.rds_instance_class
  storage_type                        = var.rds_storage_type
  manage_master_user_password         = true
  allocated_storage                   = 100
  db_name                             = "${var.project}-${var.environment}-db"
  username                            = var.rds_username
  port                                = var.rds_port
  iam_database_authentication_enabled = false
  auto_minor_version_upgrade          = false
  multi_az                            = true
  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]
  create_db_subnet_group = false
  subnet_ids = [
    module.vpc.private_subnets
  ]
  family               = "${var.rds_engine}${var.rds_engine_version}"
  major_engine_version = var.rds_engine_version
  deletion_protection  = true
  tags = {
    Name = "${var.project}-${var.environment}-rds"
    ENV  = "${var.environment}"
  }
}

module "replica-db" {
  source                              = "terraform-aws-modules/rds/aws"
  replicate_source_db                 = module.db.db_instance_identifier
  identifier                          = "${var.project}-${var.environment}-rds"
  engine                              = var.rds_engine
  engine_version                      = var.rds_engine_version
  instance_class                      = var.rds_instance_class
  storage_type                        = var.rds_storage_type
  manage_master_user_password         = true
  allocated_storage                   = 100
  db_name                             = "${var.project}-${var.environment}-db"
  username                            = var.rds_username
  port                                = var.rds_port
  iam_database_authentication_enabled = false
  auto_minor_version_upgrade          = false
  multi_az                            = false
  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]
  create_db_subnet_group = false
  subnet_ids = [
    module.vpc.private_subnets
  ]
  family               = "${var.rds_engine}${var.rds_engine_version}"
  major_engine_version = var.rds_engine_version
  deletion_protection  = true
  tags = {
    Name = "${var.project}-${var.environment}-rds"
    ENV  = "${var.environment}"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "${var.project}-${var.environment}-rds-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow MySQL from EC2 Server"
    from_port   = var.rds_port
    to_port     = var.rds_port
    protocol    = "tcp"
    security_groups = [
      aws_security_group.lt_sg.id
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
