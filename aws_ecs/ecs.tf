resource "aws_ecs_cluster" "main" {
  name = "cb-cluster"
}

data "template_file" "cb_app" {
  template = file("service.json")

  vars = {
    app_image      = var.app_image
    app_port       = var.app_port
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
  }
}
resource "aws_ecs_task_definition" "app" {
  family                = "cb-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "${aws_iam_role.ecs_role.arn}"
  cpu                      = "${var.fargate_cpu}"
  memory                   = "${var.fargate_memory}"
  container_definitions = data.template_file.cb_app.rendered

}
resource "aws_ecs_service" "main" {
  name            = "cb-service"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.app.arn}"
  desired_count   = "${var.app_count}"
  #iam_role        = "${aws_iam_role.ecs_role.arn}"
  launch_type      = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = "${aws_subnet.public.*.id}"
    assign_public_ip = true
  }
  
  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = "cb-app"
    container_port   = 80
  }
depends_on = [aws_alb_listener.front_end, aws_iam_role_policy.ecs_policy]
}

