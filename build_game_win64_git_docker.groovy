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
