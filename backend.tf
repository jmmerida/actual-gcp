terraform {
  cloud {

    organization = "PersonalTestingPlayGround"

    workspaces {
      name = "ActualDeployment"
    }
  }
}
