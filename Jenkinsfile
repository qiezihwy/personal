def repo = 'nexus.ingress.lab.gitfitlive.com'

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
  containers:
  - name: docker-client
    image: ${repo}/docker-proxy/docker:latest
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
    image: ${repo}/docker-proxy/docker:dind
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
        CONTAINER_NAME = "${repo}/docker-hosted/resume:latest"
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
                                credentialsId: 'nexus-admin',
                                usernameVariable: 'USERNAME',
                                passwordVariable: 'PASSWORD'
                            )
                        ]) {
                            sh """
                                echo "\$PASSWORD" | docker login -u "\$USERNAME"  https://${repo} --password-stdin
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


        stage('deploy at home') {
            agent {
                label 'prod && home'
            }
            steps {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'nexus-admin',
                            usernameVariable: 'USERNAME',
                            passwordVariable: 'PASSWORD'
                        )
                    ]) {
                        sh """
                            docker login -u "\$USERNAME" -p "\$PASSWORD" https://${repo}
                        """
                    }
                    echo "Pulling the docker image..."
                    sh """
                        docker pull $CONTAINER_NAME
                    """
                    echo "Pulling the docker image complete."
                    echo "starting the docker image ..."
                    sh """
                        docker stop resume && docker rm resume
                        docker run -itd -p 8080:80 --name resume --restart always $CONTAINER_NAME 
                    """
                    echo "starting the docker image complete."
            }
        }
}
}