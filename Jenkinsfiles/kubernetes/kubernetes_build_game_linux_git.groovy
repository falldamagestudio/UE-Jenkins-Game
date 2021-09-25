pipeline {
  agent {
    kubernetes { 

 
      // The given PersistentVolumeClaim will be mounted where the workspace folder typically is located.
      // The PVC must have been created beforehand, outside of Jenkins.
      // The PVC ensures that a persistent disk of a given size has been created.
      // It enables incremental builds.
      //
      // The current automation does not offer any means for creating these PVCs. If you want to
      // take advantage of persistent workspaes for Kubernetes builds, you must create the PVCs yourself.
      //
      // workspaceVolume persistentVolumeClaimWorkspaceVolume(claimName: 'build-game-linux-git-kubernetes', readOnly: false)

      yaml """
metadata:
  labels:
    app: jenkins-agent

spec:

  # Schedule this pod onto a node in the jenkins agent Linux node pool
  nodeSelector:
    jenkins-agent-linux-node-pool: "true"

  # Ensure this pod is not scheduled onto a node that already has another jenkins agent pod on it
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - jenkins-agent
        topologyKey: "kubernetes.io/hostname"

  # Allow this pod to be scheduled onto nodes in the jenkins agent Linux node pool
  tolerations:
  - key: jenkins-agent-linux-node-pool
    operator: Equal
    value: "true"
    effect: NoSchedule

  # Use root uid for volumes
  securityContext:
    fsGroup: 1000

  containers:
  - name: jnlp
  - name: ue-jenkins-buildtools-linux
    image: ${UE_JENKINS_BUILDTOOLS_LINUX_IMAGE}
    # Add dummy command to prevent container from immediately exiting upon launch
    command:
    - cat
    tty: true
"""
    }
  }

  stages {

    stage('Update UE') {

      steps {
        container('ue-jenkins-buildtools-linux') {

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
    }
      
    stage('Build game') {
      steps {
        container('ue-jenkins-buildtools-linux') {
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

}
