pipeline {

  agent {
    docker {
      // The entire job will run on one specific node
      label 'build-game-win64-git-docker'

      // All steps will be performed within this container
      image env.UE_JENKINS_BUILDTOOLS_WINDOWS_IMAGE

      // Ensure that cmd.exe is running as soon as the container has started.
      // Without this, if the container default to, for example, powershell, then Docker will report the following error:
      //  ERROR: The container started but didn't run the expected command. Please double check your ENTRYPOINT does execute the command passed as docker run argument, as required by official docker images (see https://github.com/docker-library/official-images#consistency for entrypoint consistency requirements).
      //  Alternatively you can force image entrypoint to be disabled by adding option `--entrypoint=''`.
      // The error is benign (the job will continue and will work succrssfully), but confusing.
      args '--entrypoint=cmd.exe'

      // Use a specific workspace folder, with a shorter folder name (Jenkins will default to C:\J\workspace\build_engine_windows_docker).
      // Building UE results in some long paths, and paths longer than 260 characters are problematic under Windows.
      // This shorter custom workspace name minimizes the risk that we'll run into too-long path names.
      customWorkspace "C:\\W\\Game-Win64"
    }
  }

  // Any programs that use the GCP Client Library (for example, Longtail) will by default use
  //   the provided service account
  // This makes behaviour identical between running on a GCE VM and a bare-metal host
  //
  // Besides, the GCP Client Library attempts to access the internal endpoint (169.254.169.254) to 
  //   detect the VM identity -- and if run within a Docker container on a GCE VM, traffic to that location
  //   does not work properly; the net result is that a program such as Longtail will hang indefinitely
  //   if invoked within a Docker container on a GCE VM if GOOGLE_APPLICATION_CREDENTIALS is not set
  //
  // Reference: https://github.com/jenkinsci/google-oauth-plugin/issues/6#issuecomment-431424049
  // Reference: https://cloud.google.com/docs/authentication/production#automatically
  // Reference: https://jenkinsci.github.io/kubernetes-credentials-provider-plugin/examples/

  withCredentials([[$class: 'FileBinding', credentialsId: 'build-job-gcp-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS']]) {

    stages {

      stage('Update UE') {
        steps {
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

}
