data "aws_organizations_organization" "current" {}

data "aws_organizations_organizational_units" "root" {
  parent_id = local.root_id
}

data "aws_organizations_organizational_unit_child_accounts" "root_child_ous" {
  for_each = {
    for ou in data.aws_organizations_organizational_units.root.children : ou.id => ou
  }

  parent_id = each.key
}

locals {
  root_id = data.aws_organizations_organization.current.roots[0].id

  root_child_account_ids_by_ou = {
    for ou_id, child_accounts in data.aws_organizations_organizational_unit_child_accounts.root_child_ous :
    ou_id => [for account in child_accounts.accounts : account.id]
  }

  security_ou = one([
    for ou in data.aws_organizations_organizational_units.root.children : ou
    if contains(local.root_child_account_ids_by_ou[ou.id], var.security_account_id)
  ])

  workloads_ou = one([
    for ou in data.aws_organizations_organizational_units.root.children : ou
    if contains(local.root_child_account_ids_by_ou[ou.id], var.workload_dev_account_id) &&
    contains(local.root_child_account_ids_by_ou[ou.id], var.workload_prod_account_id)
  ])

  security_ou_id  = local.security_ou.id
  workloads_ou_id = local.workloads_ou.id

  security_account = one([
    for account in data.aws_organizations_organization.current.accounts : account
    if account.id == var.security_account_id
  ])

  workload_dev_account = one([
    for account in data.aws_organizations_organization.current.accounts : account
    if account.id == var.workload_dev_account_id
  ])

  workload_prod_account = one([
    for account in data.aws_organizations_organization.current.accounts : account
    if account.id == var.workload_prod_account_id
  ])
}
