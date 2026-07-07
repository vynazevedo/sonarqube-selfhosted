data "aws_iam_policy_document" "dlm_assume" {
  count = var.enable_dlm_snapshots ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm" {
  count = var.enable_dlm_snapshots ? 1 : 0

  name_prefix        = "${var.name}-dlm-"
  assume_role_policy = data.aws_iam_policy_document.dlm_assume[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "dlm" {
  count = var.enable_dlm_snapshots ? 1 : 0

  role       = aws_iam_role.dlm[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "data" {
  count = var.enable_dlm_snapshots ? 1 : 0

  description        = "Daily snapshots of the ${var.name} data volume"
  execution_role_arn = aws_iam_role.dlm[0].arn
  state              = "ENABLED"
  tags               = var.tags

  policy_details {
    resource_types = ["VOLUME"]

    target_tags = {
      Snapshot = var.name
    }

    schedule {
      name      = "daily"
      copy_tags = true

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }

      retain_rule {
        count = var.snapshot_retention_days
      }
    }
  }
}
