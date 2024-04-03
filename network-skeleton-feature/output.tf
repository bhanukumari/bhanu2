output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

//*********************************//
output "pub_subnet_id" {
 value = aws_subnet.my_public_subnet.*.id
}

output "pri_subnet_id" {
value = aws_subnet.my_private_subnet.*.id
}

//*****************************************//
output "igw_id" {
value = aws_internet_gateway.my_igw.id
}

output "public_routeTable_id" {
  value = aws_route_table.public_routeTable.id
}

output "private_routeTable_id" {
  value = aws_route_table.private_routeTable.id
}



output "natgw_id" {
  value =  aws_nat_gateway.nat_gateway.id  
}
//*********************************************
output "eip_id" {
    value = aws_eip.nat_gateway.id
}

output "vpc_flow_log_s3_arn"{
  value = aws_s3_bucket.vpc_flow_log_s3[0].arn
}

output "alb_id" {
  description = "The id of the Application load balancer attached to VPC"
  value       = aws_lb.alb.id
}

output "web_security_group_id" {
  description = "The web_security_group_id of the VPC"
  value       = aws_security_group.web_sg.id
}

output "http_front_end_arn"{
  value = aws_lb_listener.http_front_end.arn
}