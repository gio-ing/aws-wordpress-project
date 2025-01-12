
module "bh_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.2.1"

  name = "${var.project}-${var.environment}-bh"

  ami                    = var.ami_id_bh
  instance_type          = var.bh_ec2_type
  vpc_security_group_ids = [aws_security_group.bh_ec2_sg.id]
  subnet_id              = module.vpc.public_subnets[0].id
  iam_instance_profile   = aws_iam_instance_profile.bh_instance_role.name
  root_block_device = [{
    encrypted             = true
    volume_type           = "standard"
    volume_size           = var.bh_volume_size
    delete_on_termination = true
  }]
  tags = {
    Env       = var.environment
    Function  = "BH"
    Terraform = true
  }
}

resource "aws_iam_instance_profile" "bh_instance_role" {
  name = "${var.project}-${var.environment}-bh-instance-role"
  role = aws_iam_role.bh_instance_role.name
}

resource "aws_iam_role_policy_attachment" "bh_instance_role_policy_attachment" {
  role       = aws_iam_role.bh_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role" "bh_instance_role" {
  name = "${var.project}-${var.environment}-bh-instance-role"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Effect" : "Allow"
        }
      ]
    }
  )
}

resource "aws_security_group" "bh_ec2_sg" {
  name        = "${var.project}-${var.environment}-bh-ec2-sg"
  description = "${var.project}-${var.environment}-bh-ec2-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "allow SSH from Agency"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.agency_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name   = "${var.project}-${var.environment}-alb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_lb" "alb" {
  name            = "${var.project}-${var.environment}-alb"
  subnets         = module.vpc.public_subnets.id
  security_groups = [aws_security_group.alb_sg.id]
  access_logs {
    bucket  = module.s3_bucket_for_logs.s3_bucket_id
    prefix  = "${var.project}-${var.environment}-alb-logs"
    enabled = true
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "${var.project}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_security_group" "lt_sg" {
  name   = "${var.project}-${var.environment}-lt"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_iam_role" "launch_template_role" {
  name = "lt-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_instance_profile" "lt_profile" {
  name = "lt_profile"
  role = aws_iam_role.launch_template_role.name
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = module.db.db_instance_master_user_secret_arn
}

resource "aws_launch_template" "lt" {
  name          = "${var.project}-${var.environment}-lt"
  image_id      = var.ami_id_ec2
  instance_type = var.ec2_type
  iam_instance_profile {
    name = aws_iam_instance_profile.lt_profile.name
  }
  vpc_security_group_ids = [aws_security_group.lt_sg.id]

  user_data = base64encode(templatefile("./scripts/user-data.sh", {
    region      = var.aws_region
    db_user     = module.db.db_instance_username
    db_name     = module.db.db_instance_name
    db_pwd      = data.aws_secretsmanager_secret_version.db_password
    db_endpoint = module.db.db_instance_identifier
    wp_version  = var.wp_version
    efs_dns     = aws_efs_file_system.wordpress_efs.dns_name
  }))

}

resource "aws_autoscaling_group" "asg" {
  name = "${var.project}-${var.environment}-asg"
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  vpc_zone_identifier = module.vpc.private_subnets.id
  target_group_arns   = [aws_lb_target_group.alb_tg.arn]
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_autoscaling_policy" "asg_policy" {
  name                      = "${var.project}-${var.environment}-asp-policy"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 120
  autoscaling_group_name    = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    target_value = 100
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.alb.arn_suffix}/${aws_lb_target_group.alb_tg.arn_suffix}"
    }
  }
}

