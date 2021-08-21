pipeline {

  agent {
    docker {
      // The entire job will run on one specific node
      label 'build-game-linux-git-docker-static'

      // All steps will be performed within this container
      image env.UE_JENKINS_BUILDTOOLS_LINUX_IMAGE
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
          sh """
              ./Scripts/Linux/BuildSteps/UpdateUE.sh ${LONGTAIL_STORE_BUCKET_NAME}
          """
        }
      }
    }
      
    stage('Build game') {
      steps {
        script {
            sh "rm -rf Logs"
          try {
            sh """
                ./Scripts/Linux/BuildSteps/BuildGame.sh \$(realpath ./ExampleGame/ExampleGame.uproject) Linux Development ExampleGame \$(realpath ./LocallyBuiltGame) \$(realpath ./Logs)
            """
          } finally {
            archiveArtifacts 'Logs/**/*'
          }
        }
      }
    }

  }

}
