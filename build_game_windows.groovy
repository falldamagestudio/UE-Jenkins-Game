pipeline {
  agent {
    kubernetes { 

      // The given PersistentVolumeClaim will be mounted where the workspace folder typically is located.
	    // The PVC must have been created beforehand, outside of Jenkins.
	    // The PVC ensures that a persistent disk of a given size has been created.
	    // It enables incremental builds.
      workspaceVolume persistentVolumeClaimWorkspaceVolume(claimName: 'build-game-windows', readOnly: false)

      // Provisioning a new Windows node, fetching the Windows Server Core base image,
      //  and the MSVC build tools layers can take a long time.
      // Allow for up to 30 minutes for this process to complete.
      slaveConnectTimeout 1800

      yaml """
metadata:
  labels:
    app: jenkins-agent

spec:

  # Schedule this pod onto a node in the jenkins agent Windows node pool
  nodeSelector:
    jenkins-agent-windows-node-pool: "true"

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

  # Allow this pod to be scheduled onto nodes in the jenkins agent Windows node pool
  tolerations:
  - key: jenkins-agent-windows-node-pool
    operator: Equal
    value: "true"
    effect: NoSchedule
  # Allow this pod to be scheduled onto nodes with Windows as host OS
  - key: node.kubernetes.io/os
    operator: Equal
    value: "windows"
    effect: NoSchedule

  containers:

  - name: jnlp
    # Use Windows agent image
    image: ${UE_JENKINS_INBOUND_AGENT_WINDOWS_IMAGE}
    # Use short working directory to avoid problems with long paths on Windows;
    #  all other containers will use this same working dir as well
    #  and the work folder for the pipeline script will become <WORKINGDIR>/workspace/<jobname>
    #  -- and this path should be less than 50 characters in total on Windows
    #  (or else building UE software will run into the 248/260 char path limits)
    workingDir: C:\\J

  - name: ue-jenkins-buildtools-windows
    image: ${UE_JENKINS_BUILDTOOLS_WINDOWS_IMAGE}
    # Add dummy command to prevent container from immediately exiting upon launch
    command:
    - powershell
    args:
    - Start-Sleep
      999999
"""
    }
  }

  stages {

    stage('Update UE') {
      steps {
        container('ue-jenkins-buildtools-windows') {
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
        container('ue-jenkins-buildtools-windows') {
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
