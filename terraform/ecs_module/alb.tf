# tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group" "alb_sg" {
  name        = "genea-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
  from_port       = 8000
  to_port         = 8000
  protocol        = "tcp"
  security_groups = [aws_security_group.ecs_service_sg.id]
  description     = "ALB to ECS service traffic only"
}
}


# tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "genea_alb" {
  name               = "genea-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.pub_subnet_ids
}

resource "aws_lb_target_group" "genea_tg" {
  name        = "genea-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# tfsec:ignore:aws-elb-http-not-used
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.genea_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.genea_tg.arn
  }

  
}

output "alb_hostname" {
  value = aws_lb.genea_alb.dns_name
}