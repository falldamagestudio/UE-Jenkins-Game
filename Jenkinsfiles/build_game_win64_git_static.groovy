pipeline {

  agent {
    node {
      // The entire job will run on one specific node
      label 'build-game-win64-git-static'

      // Use a specific workspace folder, with a shorter folder name (Jenkins will default to C:\J\workspace\build_engine_windows_docker).
      // Building UE results in some long paths, and paths longer than 260 characters are problematic under Windows.
      // This shorter custom workspace name minimizes the risk that we'll run into too-long path names.
      customWorkspace "C:\\W\\Game-Win64"
    }
  }

  stages {

    stage('Update UE') {

      steps {

        // Ensure that any program that uses the GCP Client Library (for example, Longtail) uses
        //   the provide service account as its identity.
        //
        // This makes the application autheticate identically in different environments,
        //   regardless of whether it's run on a bare-metal host, a GCE VM, or in a GKE Pod,
        //   regardless of whether it's run within a Docker container or natively.
        //
        // In addition, the GCP Client Library attempts to access the internal endpoint (169.254.169.254) to 
        //   figure out if it's run on GCE/GKE and then pick its identity -- and if run within a Docker
        //   container on a GCE VM, traffic to that endpoint does not get routed properly by default; the net
        //   result is that a program such as Longtail will hang indefinitely if invoked within a Docker
        //   container on a GCE VM where GOOGLE_APPLICATION_CREDENTIALS is not set.
        //
        // Reference: https://github.com/jenkinsci/google-oauth-plugin/issues/6#issuecomment-431424049
        // Reference: https://cloud.google.com/docs/authentication/production#automatically
        // Reference: https://jenkinsci.github.io/kubernetes-credentials-provider-plugin/examples/

        withCredentials([[$class: 'FileBinding', credentialsId: 'build-job-gcp-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS']]) {

          powershell """
            try {
              & .\\Scripts\\Windows\\BuildSteps\\UpdateUE.ps1 -CloudStorageBucket ${LONGTAIL_STORE_BUCKET_NAME}
            } catch {
              Write-Error \$_
              exit 1
            }
          """
        }
      }
    }
      
    stage('Build game') {
      steps {
        powershell """
          try {
            & .\\Scripts\\Windows\\BuildSteps\\BuildGame.ps1 -ProjectLocation ExampleGame\\ExampleGame.uproject -TargetPlatform Win64 -Configuration Development -Target ExampleGame -ArchiveDir LocallyBuiltGame
          } catch {
            Write-Error \$_
            exit 1
          }
        """
      }
    }

  }

}
