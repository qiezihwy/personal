pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: docker-builder
spec:
  imagePullSecrets:
    - name: hub-auth
  containers:
  - name: docker-client
    image: harbor.ingress.lab.gitfitlive.com/mirror/docker:latest
    command: ['cat']
    tty: true
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2376
    - name: DOCKER_TLS_CERTDIR
      value: "/certs"
    - name: DOCKER_CERT_PATH
      value: "/certs/client"
    - name: DOCKER_TLS_VERIFY
      value: "1"
    volumeMounts:
    - name: docker-certs
      mountPath: /certs
      readOnly: true
  - name: docker-dind
    image: harbor.ingress.lab.gitfitlive.com/mirror/docker:dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: "/certs"
    volumeMounts:
    - name: docker-certs
      mountPath: /certs
  volumes:
  - name: docker-certs
    emptyDir: {}
"""
        }
    }
    
    environment {
        HARBOR = 'harbor.ingress.lab.gitfitlive.com'
        CONTAINER_NAME = 'harbor.ingress.lab.gitfitlive.com/oasis/resume:latest'
    }
    
    stages {
        stage('Docker Build') {
            steps {
                container('docker-client') {
                    script {
                        echo "等待 Docker 服务就绪..."
                        retry(30) {
                            sleep 3
                            sh """
                                if ! docker info > /dev/null 2>&1; then
                                    echo "Docker 守护进程未就绪，等待 10 秒..."
                                    exit 1
                                fi
                            """
                        }
                        
                        withCredentials([
                            usernamePassword(
                                credentialsId: 'harbor-credentials',
                                usernameVariable: 'HARBOR_USERNAME',
                                passwordVariable: 'HARBOR_PASSWORD'
                            )
                        ]) {
                            sh """
                                docker login -u "\$HARBOR_USERNAME" -p "\$HARBOR_PASSWORD" https://harbor.ingress.lab.gitfitlive.com
                            """
                        }
                        
                        echo "Packing the docker image..."
                        sh """
                            docker build -t $CONTAINER_NAME .
                            docker push $CONTAINER_NAME
                        """
                        echo "Packing the docker image complete."
                    }
                }
            }
        }
    }
}