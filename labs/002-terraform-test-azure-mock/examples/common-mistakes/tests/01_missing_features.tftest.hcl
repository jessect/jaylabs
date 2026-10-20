# Real provider, no mocks, and no `features {}` block.
# Error: The argument "features" is required, but no definition was found.
run "plan_without_features" {
  command = plan

  module {
    source = "./no-features"
  }
}
