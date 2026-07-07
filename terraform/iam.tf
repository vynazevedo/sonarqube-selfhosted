data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name_prefix        = "${var.name}-"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.name}-"
  role        = aws_iam_role.instance.name
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy_document" "ssm_read" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.db_password.arn]
  }
}

resource "aws_iam_role_policy" "ssm_read" {
  name   = "db-password-read"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.ssm_read.json
}

data "aws_iam_policy_document" "backup" {
  count = var.create_backup_bucket ? 1 : 0

  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.backups[0].arn}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.backups[0].arn]
  }
}

resource "aws_iam_role_policy" "backup" {
  count = var.create_backup_bucket ? 1 : 0

  name   = "backup-bucket-access"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.backup[0].json
}
