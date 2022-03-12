inputs = merge(
    read_terragrunt_config(find_in_parent_folders("global.hcl")).inputs,
    {
        project_name = "${basename(get_terragrunt_dir())}"
    }
)
