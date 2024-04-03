resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "my_public_subnet" {
  count  = length(var.pub_subnet_cidr)
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block        = element(var.pub_subnet_cidr , count.index)
  availability_zone = element(var.subnet_az ,count.index)
  tags = {
    Name = element(var.pub_subnet_name ,count.index)
  }
}

resource "aws_subnet" "my_private_subnet" {

  count  = length(var.pri_subnet_cidr)
  cidr_block = var.pri_subnet_cidr[count.index]
  vpc_id                  = aws_vpc.my_vpc.id

  availability_zone = element(var.subnet_az ,count.index)

  tags = {
    Name = element(var.pri_subnet_name ,count.index)
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = var.igw_name
  }
}

resource "aws_route_table" "public_routeTable" {
  vpc_id =  aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
Name = var.public_rt_name
}
}

resource "aws_route_table_association" "public_rt_association" {
  count          = length(var.pub_subnet_cidr)
  subnet_id      = element(aws_subnet.my_public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_routeTable.id
}

resource "aws_route_table_association" "private_rt_association" {
  count          = length(var.pri_subnet_cidr)
  subnet_id      = element(aws_subnet.my_private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_routeTable.id
}

resource "aws_route_table" "private_routeTable" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id 
    # gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = { 
Name = var.private_rt_name
}
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
    allocation_id = aws_eip.nat_gateway.id
    subnet_id = aws_subnet.my_public_subnet[0].id

}

//*********************************************

resource "aws_flow_log" "vpc_flow_logs" {
  count                = var.enable_vpc_logs == true ? 1 : 0
  log_destination      = aws_s3_bucket.vpc_flow_log_s3[0].arn
  
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.my_vpc.id
}

resource "aws_s3_bucket" "vpc_flow_log_s3" {
  count  = var.enable_vpc_logs == true ? 1 : 0
  bucket = var.vpc_flow_log_s3_name
}

data "aws_iam_policy_document" "log_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup", 
      "logs:CreateLogDelivery",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

# Create an IAM role for VPC flow logs
resource "aws_iam_role" "vpc_flow_logs" {
   count  = var.enable_vpc_logs == true ? 1 : 0
   name = var.vpc-flow-logs-role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# Attach a policy to the IAM role for VPC flow logs
resource "aws_iam_role_policy" "iam_log_policy" {
   count  = var.enable_vpc_logs == true ? 1 : 0
  name   = "vpc-flow-log-policy"
  role   = aws_iam_role.vpc_flow_logs[count.index].id
  policy = data.aws_iam_policy_document.log_policy.json
}

resource "aws_lb" "alb"{
  internal             = false
  load_balancer_type   = "application"
  security_groups      = [aws_security_group.web_sg.id]
  subnets              = aws_subnet.my_public_subnet.*.id
  tags = {
    Name = "alb"
  }
}

resource "aws_lb_listener" "http_front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type          = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_security_group" "web_sg" {
  description  = "Web security group"
  vpc_id       = aws_vpc.my_vpc.id
  tags = {
    name = "sg"
 }
}

resource "aws_security_group_rule" "sg_egress" {
  count             = length(var.sg_egress_to_port)
  type              = "egress"
  from_port         = element(var.sg_egress_from_port,count.index)
  to_port           = element(var.sg_egress_to_port,count.index)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
 security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "sg_ingress" {
  count             = length(var.sg_ingress_to_port)
  type              = "ingress"
  from_port         = element(var.sg_ingress_from_port,count.index)
  to_port           = element(var.sg_ingress_to_port,count.index)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_sg.id
}