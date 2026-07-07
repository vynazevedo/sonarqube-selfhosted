resource "aws_instance" "this" {
  ami                         = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  ebs_optimized               = true
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/templates/user-data.sh.tftpl", {
    compose_file     = file("${path.module}/../docker/docker-compose.yml")
    caddyfile        = file("${path.module}/../docker/Caddyfile")
    region           = data.aws_region.current.region
    ssm_parameter    = aws_ssm_parameter.db_password.name
    domain           = var.domain
    acme_email       = var.acme_email
    sonarqube_image  = var.sonarqube_image
    db_user          = var.db_user
    db_name          = var.db_name
    compose_version  = var.compose_version
    volume_id_nodash = replace(aws_ebs_volume.data.id, "-", "")
    backup_bucket    = var.create_backup_bucket ? local.backup_bucket_name : ""
    enable_cw_agent  = var.enable_cloudwatch_alarms
    extra_env        = var.extra_env
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = data.aws_subnet.this.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true
  snapshot_id       = var.data_volume_snapshot_id

  tags = merge(var.tags, {
    Name     = "${var.name}-data"
    Snapshot = var.name
  })
}

resource "aws_volume_attachment" "data" {
  device_name                    = "/dev/sdf"
  volume_id                      = aws_ebs_volume.data.id
  instance_id                    = aws_instance.this.id
  stop_instance_before_detaching = true
}

resource "aws_eip" "this" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = var.name })
}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this.id
}
